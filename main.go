// Package main provides various examples of Fyne API capabilities.
package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"io"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	_ "net/http/pprof"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	fyne "fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
	findfont "github.com/flopp/go-findfont"
	ps "github.com/mitchellh/go-ps"
	// "fyne.io/fyne/v2/app"
	// "fyne.io/fyne/v2/cmd/fyne_demo/tutorials"
	// "fyne.io/fyne/v2/cmd/fyne_settings/settings"
	// "fyne.io/fyne/v2/container"
	// "fyne.io/fyne/v2/layout"
	// "fyne.io/fyne/v2/theme"
	// "fyne.io/fyne/v2/widget"
)

const preferenceCurrentTutorial = "currentTutorial"

var isWindows = runtime.GOOS == "windows"
var topWindow fyne.Window

func shortcutFocused(s fyne.Shortcut, w fyne.Window) {
	if focused, ok := w.Canvas().Focused().(fyne.Shortcutable); ok {
		focused.TypedShortcut(s)
	}
}

func main() {
	go http.ListenAndServe(":12345", nil)

	executeFile, _ := os.Executable()
	executeFile, _ = filepath.Abs(executeFile)

	var showFont bool
	flag.BoolVar(&showFont, "show_font", false, "show system font")
	flag.Parse()

	fontPaths := findfont.List()
	for _, path := range fontPaths {
		if showFont {
			fmt.Println(path)
		}
		//楷体:simkai.ttf
		//黑体:simhei.ttf
		if strings.Contains(path, "simhei.ttf") {
			os.Setenv("FYNE_FONT", path)
			if !showFont {
				break
			}
		}
	}

	a := app.NewWithID("io.fyne.demo")
	a.SetIcon(theme.FyneLogo())
	w := a.NewWindow("Fyne Demo")
	topWindow = w
	w.SetMaster()

	var serverInstance ServerInstance
	serverInstance.rootDir = filepath.Dir(executeFile)
	serverInstance.imageDir = filepath.Join(serverInstance.rootDir, "images")
	serverInstance.c = make(chan func())

	var wait sync.WaitGroup

	wait.Add(1)
	go func() {
		wait.Done()

		serverInstance.runLoop()
	}()
	w.SetOnClosed(func() {
		close(serverInstance.c)
		wait.Wait()
	})

	statusBar := makeStatusBar(w)
	nodeTab, setServerInfo := makeNodeTab(w, &serverInstance)
	entryTab := makeEntryTab(w, &serverInstance)
	split := container.NewHSplit(entryTab, nodeTab)
	split.Offset = 0.65
	w.SetContent(container.NewBorder(nil, statusBar, nil, nil, split))
	w.Resize(fyne.NewSize(640, 460))

	showConnectSettings(w, func(address string) error {
		data, err := readServerInfo(Join(address, "/api/accessPointList"))
		if err != nil {
			return err
		}
		serverInstance.address = address
		serverInstance.serverInfo = data
		setServerInfo(data)
		return nil
	})
	w.ShowAndRun()
}

func showConnectSettings(win fyne.Window, cb func(string) error) {
	//var validateErr error
	selectEntry := widget.NewSelectEntry([]string{"http://127.0.0.1:8000"})
	selectEntry.PlaceHolder = "请输入或选择"
	//selectEntry.Validator = fyne.StringValidator(func(s string) error {
	//	return validateErr
	//})
	size := selectEntry.MinSize()
	size.Width += 50
	selectEntry.Resize(size)
	selectEntry.SetText("http://127.0.0.1:8000")
	selectItem := widget.NewFormItem("地址", selectEntry)
	//selectItem.HintText = "OK"
	items := []*widget.FormItem{
		selectItem,
	}

	var dlg dialog.Dialog
	dlg = dialog.NewForm("连接...", "确定", "取消", items, func(b bool) {
		if !b {
			win.Close()
			return
		}

		progress := dialog.NewProgressInfinite("连接中", "正在读服务器信息......", win)
		progress.Show()

		validateErr := cb(selectEntry.Text)
		progress.Hide()
		if validateErr != nil {
			dlgError := dialog.NewError(validateErr, win)
			dlgError.SetOnClosed(func() {
				dlg.Show()
			})
			dlgError.Show()
		}
	}, win)
	dlg.Show()
}

func makeStatusBar(_ fyne.Window) fyne.CanvasObject {
	a := fyne.CurrentApp()
	return container.NewHBox(
		widget.NewButton("Dark", func() {
			a.Settings().SetTheme(theme.DarkTheme())
		}),
		widget.NewButton("Light", func() {
			a.Settings().SetTheme(theme.LightTheme())
		}),
		layout.NewSpacer(),
		widget.NewButton("Settings", func() {
			a.Settings().SetTheme(theme.LightTheme())
		}),
	)
}

func makeEntryTab(_ fyne.Window, serverInstance *ServerInstance) fyne.CanvasObject {
	entry := widget.NewEntry()
	entry.SetPlaceHolder("请输入用户名")

	serverInstance.GetUsername = func() string {
		return entry.Text
	}

	content := canvas.NewImageFromResource(theme.FyneLogo())
	content.FillMode = canvas.ImageFillContain
	serverInstance.SetImage = func(img image.Image) {
		content.Resource = nil
		content.Image = img
		content.Refresh()
	}

	serverInstance.GetImage = func() image.Image {
		return content.Image
	}

	return container.NewBorder(entry, nil, nil, nil, content)
}

func makeListTab(_ fyne.Window, serverInstance *ServerInstance) (fyne.CanvasObject, func(*ServerInfo)) {

	setErrorText := serverInstance.SetMessageText
	var srvInfo = &ServerInfo{}

	// icon := widget.NewIcon(nil)
	// label := widget.NewLabel("Select An Item From The List")
	// hbox := container.NewHBox(icon, label)

	var buttons []*widget.Button

	resetButtons := func() {
		for _, btn := range buttons {
			btn.SetText("申请")
			btn.Enable()
		}
	}

	serverInstance.OnDisconnected = resetButtons

	list := widget.NewList(
		func() int {
			return len(srvInfo.Nodes)
		},
		func() fyne.CanvasObject {
			return container.NewBorder(nil, nil, container.NewHBox(
				widget.NewIcon(theme.DocumentIcon()),
				widget.NewLabel(""),
			), widget.NewButton("申请", func() {}))
		},
		func(id widget.ListItemID, item fyne.CanvasObject) {
			items := item.(*fyne.Container).Objects[0].(*fyne.Container)
			items.Objects[1].(*widget.Label).SetText(srvInfo.Nodes[id].Name)
			button := item.(*fyne.Container).Objects[1].(*widget.Button)
			button.OnTapped = func() {
				for _, btn := range buttons {
					if btn != button {
						btn.Disable()
					}
				}

				if serverInstance.IsUnconnect() {
					setErrorText(theme.ErrorColor(), "申请中...")
					button.SetText("取消")
					serverInstance.Connect(srvInfo, &srvInfo.Nodes[id], func(state connState, msg string) {
						switch state {
						case unconnected:
							setErrorText(theme.ErrorColor(), msg)
							resetButtons()
						case connecting:
							setErrorText(theme.TextColor(), "正在申请中...")
							button.SetText("取消")
						case connected:
							setErrorText(theme.TextColor(), "已连接成功")
							button.SetText("断开")
						}
					})
				} else if serverInstance.IsConnecting() {
					serverInstance.Cancel()
				} else if serverInstance.IsConnected() {
					serverInstance.Disconnect()
				}
			}
			buttons = append(buttons, button)
		},
	)

	return list, func(data *ServerInfo) {
		srvInfo = data
		list.Refresh()
	}
}

func makeNodeTab(_ fyne.Window, serverInstance *ServerInstance) (fyne.CanvasObject, func(*ServerInfo)) {
	title := canvas.NewText("错误显示在这里", theme.ErrorColor())
	title.Alignment = fyne.TextAlignTrailing

	serverInstance.SetMessageText = func(textcolor color.Color, s string) {
		title.Color = textcolor

		var sb strings.Builder
		for idx, r := range s {
			if idx > 0 && idx%30 == 0 {
				sb.WriteString("\n")
			}
			sb.WriteRune(r)
		}
		title.Text = sb.String()
		title.Refresh()
	}

	content, set := makeListTab(nil, serverInstance)
	return container.NewBorder(title, nil, nil, nil, content), set
}

type NodeInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	IP   string `json:"ip"`
}

type ServerInfo struct {
	RequestPollInterval int        `json:"request_poll_interval"`
	RequestTimeout      int        `json:"request_timeout"`
	MediaServerURL      string     `json:"media_server"`
	Nodes               []NodeInfo `json:"list"`
}

func Join(base string, paths ...string) string {
	var buf strings.Builder
	buf.WriteString(base)

	lastSplash := strings.HasSuffix(base, "/")
	for _, pa := range paths {
		if 0 == len(pa) {
			continue
		}

		if lastSplash {
			if '/' == pa[0] {
				buf.WriteString(pa[1:])
			} else {
				buf.WriteString(pa)
			}
		} else {
			if '/' != pa[0] {
				buf.WriteString("/")
			}
			buf.WriteString(pa)
		}

		lastSplash = strings.HasSuffix(pa, "/")
	}
	return buf.String()
}

func errWrap(err error, msg string) error {
	return errors.New(msg + ": " + err.Error())
}
func errResponse(response *http.Response) error {
	bs, err := ioutil.ReadAll(response.Body)
	if err != nil || len(bs) == 0 {
		return errors.New(response.Status)
	}
	var res struct {
		Msg string `json:"msg,omitempty"`
	}

	if err := json.Unmarshal(bs, &res); err == nil && res.Msg != "" {
		return errors.New(res.Msg)
	}

	return errors.New(string(bs))
}

func readServerInfo(u string) (*ServerInfo, error) {
	response, err := http.Get(u)
	if err != nil {
		return nil, errWrap(err, "连接失败")
	}

	if response.StatusCode != http.StatusOK {
		return nil, errResponse(response)
	}
	var srvInfo ServerInfo
	err = json.NewDecoder(response.Body).Decode(&srvInfo)
	if err != nil {
		return nil, errWrap(err, "解析响应失败")
	}
	return &srvInfo, nil
}

type connState int32

const (
	unconnected connState = iota
	connecting
	connected
)

func (state connState) String() string {
	switch state {
	case unconnected:
		return "unconnected"
	case connecting:
		return "connecting"
	case connected:
		return "connected"
	default:
		return fmt.Sprintf("unknown(%d)", int32(state))
	}
}

type ServerInstance struct {
	rootDir        string
	imageDir       string
	address        string
	serverInfo     *ServerInfo
	SetMessageText func(color.Color, string)
	SetImage       func(filename image.Image)
	GetImage       func() image.Image
	GetUsername    func() string
	OnDisconnected func()

	mu          sync.Mutex
	state       connState
	kill        func()
	stopWait    *sync.WaitGroup
	connectID   string
	connectAt   time.Time
	stateChange func(connState, string)

	c chan func()
}

// FileExists 文件是否存在
func FileExists(dir string, e ...*error) bool {
	info, err := os.Stat(dir)
	if err != nil {
		if len(e) != 0 {
			*e[0] = err
		}
		return false
	}

	return !info.IsDir()
}

func (si *ServerInstance) StartCaptureCam() {
	si.mu.Lock()
	defer si.mu.Unlock()

	si.startCaptureCam()
}

func (si *ServerInstance) startCaptureCam() {
	if si.stopWait != nil {
		return
	}

	var cmd *exec.Cmd
	if isWindows {
		filename := filepath.Join(si.rootDir, "toimages.bat")
		if FileExists(filename) {
			cmd = exec.Command(filename)
		} else {
			cmd = exec.Command("ffmpeg", "-f", "vfwcap", "-i", "0", "-r", "25", "-f", "-y", "-f", "image2",
				filepath.Join(si.imageDir, "image-%d.jpg"))
			cmd.Dir = si.rootDir
		}
	} else {
		filename := filepath.Join(si.rootDir, "toimages.sh")
		if FileExists(filename) {
			cmd = exec.Command("sh", filename)
		} else {
			cmd = exec.Command(filepath.Join(si.rootDir, "ffmpeg/bin/ffmpeg"), "-f", "v4l2",
				"-r", "25", "-i", "/dev/video0", "-s", "640x480",
				"-f", "image2", filepath.Join(si.imageDir, "image-%d.jpg"))

			envList := os.Environ()

			found := false
			for idx := range envList {
				if strings.HasPrefix(envList[idx], "LD_LIBRARY_PATH=") {
					envList[idx] = envList[idx] + ":" + filepath.Join(si.rootDir, "ffmpeg/lib/")
					found = true
				}
			}
			if !found {
				envList = append(envList, "LD_LIBRARY_PATH="+filepath.Join(si.rootDir, "ffmpeg/lib/"))
			}

			if len(cmd.Env) == 0 {
				cmd.Env = envList
			} else {
				cmd.Env = append(cmd.Env, envList...)
			}
		}
	}

	stopWait := new(sync.WaitGroup)
	stopWait.Add(1)
	si.stopWait = stopWait

	go func() {
		defer stopWait.Done()

		for si.IsUnconnect() {
			if err := os.MkdirAll(si.imageDir, 0777); err != nil {
				if !os.IsExist(err) {
					log.Println(err)
				}
			}

			var copyed exec.Cmd
			copyed.Path = cmd.Path
			copyed.Args = cmd.Args
			copyed.Env = cmd.Env
			copyed.Dir = cmd.Dir

			si.mu.Lock()
			si.kill = func() {
				if copyed.Process != nil {
					kill(copyed.Process.Pid)
					copyed.Process.Kill()

				}
				killByName("ffmpeg")
			}
			si.mu.Unlock()

			err := copyed.Run()
			if err != nil {
				if !si.IsUnconnect() {
					break
				}

				log.Println(err, si.status())
				// si.SetMessageText(theme.ErrorColor(), err.Error())
				time.Sleep(1 * time.Second)
			} else {
				si.SetMessageText(theme.TextColor(), "")
			}
		}
	}()
}

func (si *ServerInstance) StopCaptureCam() {
	si.mu.Lock()
	defer si.mu.Unlock()

	si.stopCaptureCam()
}

func (si *ServerInstance) stopCaptureCam() {
	if si.stopWait == nil {
		return
	}
	if si.kill != nil {
		si.kill()
	}
	si.stopWait.Wait()
	si.stopWait = nil
	si.kill = nil
}

func (si *ServerInstance) startCaptureScreen() {
	if si.stopWait != nil {
		return
	}

	var cmd *exec.Cmd
	if isWindows {
		filename := filepath.Join(si.rootDir, "screenToMediaServer.bat")
		if FileExists(filename) {
			cmd = exec.Command(filename, si.serverInfo.MediaServerURL+si.connectID)
		} else {
			cmd = exec.Command("ffmpeg", "-f", "gdigrab", "-framerate", "15", "-i", "desktop", "-vcodec", "libx264", "-f", "flv",
				si.serverInfo.MediaServerURL+si.connectID)
			cmd.Dir = si.rootDir
		}
	} else {
		filename := filepath.Join(si.rootDir, "screenToMediaServer.sh")
		if FileExists(filename) {
			cmd = exec.Command("sh", filename)
		} else {
			cmd = exec.Command(filepath.Join(si.rootDir, "ffmpeg/bin/ffmpeg"),
				"-f", "x11grab", "-framerate", "25", "-i", ":0.0", "-vcodec", "libx264", "-f", "flv",
				si.serverInfo.MediaServerURL+si.connectID)

			envList := os.Environ()

			found := false
			for idx := range envList {
				if strings.HasPrefix(envList[idx], "LD_LIBRARY_PATH=") {
					envList[idx] = envList[idx] + ":" + filepath.Join(si.rootDir, "ffmpeg/lib/")
					found = true
				}
			}
			if !found {
				envList = append(envList, "LD_LIBRARY_PATH="+filepath.Join(si.rootDir, "ffmpeg/lib/"))
			}

			if len(cmd.Env) == 0 {
				cmd.Env = envList
			} else {
				cmd.Env = append(cmd.Env, envList...)
			}
		}
	}

	stopWait := new(sync.WaitGroup)
	stopWait.Add(1)
	si.stopWait = stopWait

	go func() {
		defer stopWait.Done()

		var copyed exec.Cmd
		copyed.Path = cmd.Path
		copyed.Args = cmd.Args
		copyed.Env = cmd.Env
		copyed.Dir = cmd.Dir

		si.mu.Lock()
		si.kill = func() {
			if copyed.Process != nil {
				kill(copyed.Process.Pid)
				copyed.Process.Kill()

			}
			killByName("ffmpeg")
		}
		si.mu.Unlock()

		err := copyed.Run()
		if err != nil {
			if !si.IsConnected() {
				return
			}
			si.mu.Lock()
			defer si.mu.Unlock()

			log.Println(err, si.status())
			si.SetMessageText(theme.ErrorColor(), "屏幕捕获失败，断开连接")
			si.onDisconnected(theme.ErrorColor(), "屏幕捕获失败，断开连接")

			// time.Sleep(1 * time.Second)
		} else {
			si.mu.Lock()
			defer si.mu.Unlock()
			si.SetMessageText(theme.TextColor(), "")
			si.onDisconnected(theme.TextColor(), "")
		}
	}()
}

func (si *ServerInstance) stopCaptureScreen() {
	if si.stopWait == nil {
		return
	}
	if si.kill != nil {
		si.kill()
	}
	si.stopWait.Wait()
	si.stopWait = nil
	si.kill = nil
}

var cachedBytes = make([]byte, 0, 1*1024*1024)

func (si *ServerInstance) startConnect(srv *ServerInfo, ni *NodeInfo) error {
	username := si.GetUsername()
	if username == "" {
		return errors.New("请输入用户名")
	}
	img := si.GetImage()
	if img == nil {
		return errors.New("请稍等摄像头还没准备好")
	}
	buf := bytes.NewBuffer(cachedBytes[:0])
	w := multipart.NewWriter(buf)
	w.WriteField("name", username)
	w.WriteField("accessPointId", ni.ID)
	imageWriter, _ := w.CreateFormFile("image", "image.jpg")
	jpeg.Encode(imageWriter, img, nil)
	w.Close()

	response, err := http.Post(Join(si.address, "/api/link/apply"), "multipart/form-data; boundary="+w.Boundary(), buf)
	if err != nil {
		return errWrap(err, "申请失败")
	}

	if response.StatusCode != http.StatusOK {
		return errResponse(response)
	}

	var res struct {
		ID  string `json:"id"`
		Msg string `json:"msg"`
	}

	err = json.NewDecoder(response.Body).Decode(&res)
	if err != nil {
		return errWrap(err, "申请失败")
	}

	if res.ID == "" {
		return errors.New("申请失败, id 为空")
	}

	si.connectID = res.ID
	si.connectAt = time.Now()
	// si.pollCounter = 0
	return nil
}

func (si *ServerInstance) TestConectOk() {
	response, err := http.Get(Join(si.address, "/api/link/"+si.connectID))
	if err != nil {
		si.mu.Lock()
		defer si.mu.Unlock()

		err = errWrap(err, "申请失败")
		si.setStatus(unconnected)
		si.stateChange(unconnected, err.Error())
		si.stateChange = nil
		return
	}

	si.mu.Lock()
	defer si.mu.Unlock()

	if response.StatusCode != http.StatusOK {
		err = errResponse(response)
		si.setStatus(unconnected)
		si.stateChange(unconnected, err.Error())
		si.stateChange = nil
		return
	}

	var res struct {
		Status string `json:"status"`
		Msg    string `json:"msg"`
	}

	err = json.NewDecoder(response.Body).Decode(&res)
	if err != nil {
		err = errWrap(err, "申请失败")
		si.setStatus(unconnected)
		si.stateChange(unconnected, err.Error())
		si.stateChange = nil
		return
	}

	switch res.Status {
	case "fail":
		if res.Msg == "" {
			res.Msg = "申请失败"
		}
		si.setStatus(unconnected)
		si.stateChange(unconnected, res.Msg)
		si.stateChange = nil
	case "deny":
		if res.Msg == "" {
			res.Msg = "申请被拒绝"
		}
		si.setStatus(unconnected)
		si.stateChange(unconnected, res.Msg)
		si.stateChange = nil
	case "ok":
		if res.Msg == "" {
			res.Msg = "申请成功"
		}
		si.setStatus(connected)
		si.stateChange(connected, res.Msg)

		si.startCaptureScreen()
	case "pending":
		if time.Now().Sub(si.connectAt) > (time.Duration(si.serverInfo.RequestTimeout) * time.Second) {
			si.setStatus(unconnected)
			si.stateChange(unconnected, "超时")
			si.startCaptureScreen()
		}
	}
}

func (si *ServerInstance) TestConectionStatus() {
	ok, _ := si.getConnectStatus()
	if !ok {
		si.Cancel()
	}
}

func (si *ServerInstance) getConnectStatus() (bool, error) {
	res, err := http.Get(Join(si.address, "/api/link/"+si.connectID+"/status"))
	if err != nil {
		return false, nil
	}

	if res.StatusCode != http.StatusOK {
		return false, nil
	}

	var state struct {
		Msg    string `json:"msg"`
		Status string `json:"status"`
	}

	if res != nil && res.Body != nil {
		defer func() {
			io.Copy(ioutil.Discard, res.Body)
			res.Body.Close()
		}()
	}

	err = json.NewDecoder(res.Body).Decode(&state)
	if err != nil {
		return false, err
	}
	if state.Status == "ok" || state.Status == "on" {
		return true, nil
	}

	if state.Msg != "" {
		state.Msg = "服务器断开"
	}
	return false, errors.New(state.Msg)
}

func (si *ServerInstance) status() connState {
	return connState(atomic.LoadInt32((*int32)(&si.state)))
}

func (si *ServerInstance) setStatus(state connState) {
	atomic.StoreInt32((*int32)(&si.state), int32(state))
}

func (si *ServerInstance) runLoop() {
	ticker := time.NewTicker(20 * time.Millisecond)
	pollTicker := time.NewTicker(5 * time.Second)

	fis, err := ioutil.ReadDir(si.imageDir)
	if err == nil {
		for _, fi := range fis {
			os.Remove(filepath.Join(si.imageDir, fi.Name()))
		}
	}

	defer func() {
		si.Cancel()

		killByName("ffmpeg")
	}()
	for {
		select {
		case cb, ok := <-si.c:
			if !ok {
				return
			}
			cb()
		case <-pollTicker.C:
			switch si.status() {
			case connecting:
				si.TestConectOk()
				// fmt.Println("1")
			case connected:
				si.TestConectionStatus()
				//    fmt.Println("2")
				// default:
				//    fmt.Println("3")
			}
		case <-ticker.C:
			fis, err := ioutil.ReadDir(si.imageDir)
			if err != nil {
				if !os.IsNotExist(err) {
					log.Println(err)
				}
			}

			if len(fis) > 0 {
				if si.IsUnconnect() {
					si.StartCaptureCam()

					func() {
						for i := len(fis) - 1; i >= 0; i-- {
							filename := filepath.Join(si.imageDir, fis[i].Name())
							in, err := os.Open(filename)
							if err != nil {
								continue
							}
							defer in.Close()

							src, _, err := image.Decode(in)
							if err != nil {
								continue
							}
							si.SetImage(src)
							// fmt.Println(time.Now(), filename)
							break
						}
					}()
				}

				for _, fi := range fis {
					err := os.Remove(filepath.Join(si.imageDir, fi.Name()))
					if err != nil {
						if !strings.Contains(err.Error(), "because it is being used by another process") &&
							!strings.Contains(err.Error(), "Access is denied") {
							log.Println(err)
						}
					}
				}
			} else {
				if si.IsUnconnect() {
					si.StartCaptureCam()
				}
			}
		}
	}
}

func (si *ServerInstance) IsUnconnect() bool {
	return si.status() == unconnected
}
func (si *ServerInstance) Connect(srv *ServerInfo, ni *NodeInfo, cb func(connState, string)) {
	if atomic.CompareAndSwapInt32((*int32)(&si.state), int32(unconnected), int32(connecting)) {
		si.mu.Lock()
		defer si.mu.Unlock()
		si.stopCaptureCam()

		si.stateChange = cb

		err := si.startConnect(srv, ni)
		if err == nil {
			cb(connecting, "")
		} else {
			si.setStatus(unconnected)
			si.stateChange = nil
			cb(unconnected, err.Error())

			si.startCaptureCam()
		}
	}
}
func (si *ServerInstance) IsConnecting() bool {
	return si.status() == connecting
}
func (si *ServerInstance) Cancel() {
	if atomic.CompareAndSwapInt32((*int32)(&si.state), int32(connecting), int32(unconnected)) {

		si.mu.Lock()
		defer si.mu.Unlock()

		if si.stateChange != nil {
			si.stateChange(unconnected, "已取消")
			si.stateChange = nil
		}
	} else if atomic.CompareAndSwapInt32((*int32)(&si.state), int32(connected), int32(unconnected)) {
		si.mu.Lock()
		defer si.mu.Unlock()

		si.stopCaptureScreen()

		if si.stateChange != nil {
			si.stateChange(unconnected, "已断开")
			si.stateChange = nil
		}
	}
}
func (si *ServerInstance) IsConnected() bool {
	return si.status() == connected
}

func (si *ServerInstance) onDisconnected(c color.Color, s string) {
	req, _ := http.NewRequest("DELETE", Join(si.address, "/api/link/"+si.connectID), nil)
	res, _ := http.DefaultClient.Do(req)
	if res != nil && res.Body != nil {
		defer res.Body.Close()
		io.Copy(ioutil.Discard, res.Body)
	}

	si.setStatus(unconnected)
	si.SetMessageText(c, s)
	if si.stateChange != nil {
		si.stateChange(unconnected, s)
		si.stateChange = nil
	}
}

func (si *ServerInstance) Disconnect() {
	si.Cancel()
}

func killByPid(pid int) error {
	pr, e := os.FindProcess(pid)
	if nil != e {
		return e
	}
	defer pr.Release()
	return pr.Kill()
}
func killProcessAndChildren(pid int, processes []ps.Process) error {
	if -1 == pid {
		return nil
	}
	if nil == processes {
		var e error
		processes, e = ps.Processes()
		if nil != e {
			log.Println("killProcessAndChildren()" + e.Error())
			return killByPid(pid)
		}
	}

	for _, pr := range processes {
		if pr.PPid() == pid {
			killProcessAndChildren(pr.Pid(), processes)
		}
	}
	return killByPid(pid)
}

func killByName(name string) error {
	processes, e := ps.Processes()
	if e != nil {
		return e
	}

	for _, pr := range processes {
		if strings.Contains(pr.Executable(), name) {
			killProcessAndChildren(pr.Pid(), processes)
		}
	}
	return nil
}

func kill(pid int) error {
	return killProcessAndChildren(pid, nil)
}
