package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var dir string
var port string

func init() {
	flag.StringVar(&port, "p", "8000", "port to serve on")
	flag.StringVar(&dir, "path", "./", "the directory of static file to host")
	flag.Parse()
	if dir == "./" {
		dir, _ = os.Getwd()
	}
}
func main() {
	log.Printf("Serving %s on HTTP port: %s\n", dir, port)
	log.Fatal(http.ListenAndServe(":"+port, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.URL.Path)

		switch r.URL.Path {
		case "/api/accessPointList":
			if r.Method == http.MethodGet {
				index(w, r)
			} else {
				http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			}
		case "/api/link/apply":
			if r.Method == http.MethodPost {
				apply(w, r)
			} else {
				http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			}

		default:
			if strings.HasPrefix(r.URL.Path, "/api/link/") {
				id := strings.TrimPrefix(r.URL.Path, "/api/link/")

				if r.Method == http.MethodGet {
					readStatus(w, r, id)
					return
				} else if r.Method == http.MethodDelete {
					cancel(w, r, id)
					return
				}
			}
			http.NotFound(w, r)
		}
	})))
}

func index(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, `{
"msg":"获得接入点列表成功",
"request_poll_interval": 60,
"request_timeout": 300,
"list":[
{
"id":1,
"name":"接入点11111",
"auditDeviceId":1,
"hostName":"主机1",
"ip":"192.168.0.101",
"mask":"255.255.255.0",
"gateway":"192.168.0.1",
"status":1,
"createTime":1608246291000,
"auditDeviceName":null
},
{
"id":2,
"name":"接入点22",
"auditDeviceId":1,
"hostName":"主机22",
"ip":"192.168.0.122",
"mask":"255.255.255.0",
"gateway":"192.168.0.1",
"status":1,
"createTime":1608246305000,
"auditDeviceName":null
}
]
}`)
}

var idSeed = 0

type session struct {
	name   string
	status string
}

var sessions = map[string]session{}

func apply(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	name := r.FormValue("name")
	accessPoint := r.FormValue("accessPointId")
	file, _, err := r.FormFile("image")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer file.Close()

	if name == "fail" {
		http.Error(w, `{"code": "bad_error", "msg": "申请接入发送失败"}`, http.StatusBadRequest)
		return
	}

	if name == "notexists" {
		w.WriteHeader(http.StatusOK)
		io.WriteString(w, `{"id": "no_exists", "msg": "申请接入已发送"}`)
		return
	}

	idSeed++
	idStr := strconv.Itoa(idSeed)
	out, err := os.Create("image-" + idStr + ".jpg")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	io.Copy(out, file)
	out.Close()

	w.WriteHeader(http.StatusOK)
	io.WriteString(w, `{"id": "`+idStr+`", "msg": "申请接入已发送"}`)
	fmt.Println("name=", name)
	fmt.Println("accessPoint=", accessPoint)
	fmt.Println("image=", "image-"+idStr+".jpg")

	sessions[idStr] = session{
		name:   name,
		status: "pending",
	}

	status := "ok"
	if name == "will_deny" {
		status = "deny"
	}

	time.AfterFunc(10*time.Second, func() {
		sessions[idStr] = session{
			name:   name,
			status: status,
		}
	})
}

func readStatus(w http.ResponseWriter, r *http.Request, id string) {
	sess, ok := sessions[id]
	if ok {
		w.WriteHeader(http.StatusOK)
		io.WriteString(w, `{"status": "`+sess.status+`", "msg": "申请接入成功"}`)
		return
	}

	w.WriteHeader(http.StatusNotFound)
	io.WriteString(w, `{"code": "404", "msg": "不存在"}`)
	return
}

func cancel(w http.ResponseWriter, r *http.Request, id string) {
	delete(sessions, id)

	w.WriteHeader(http.StatusOK)
	io.WriteString(w, `{"msg": "申请接入成功"}`)
}
