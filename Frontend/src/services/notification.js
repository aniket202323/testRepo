import { Subject } from "rxjs";

const emitterNotification = new Subject();

let msg = {
  type: "",
  icon: "",
  position: "",
  closable: true,
  show: true,
  title: "",
  message: "",
};

function error(title, message = "", isSecondNotification = false) {
  emitterNotification.next({
    ...msg,
    type: "error",
    icon: "exclamation-triangle",
    title,
    message,
    isSecondNotification,
  });
}

function success(title, message = "") {
  emitterNotification.next({
    ...msg,
    type: "success",
    icon: "check",
    title,
    message,
  });
}

function warning(title, message = "") {
  emitterNotification.next({
    ...msg,
    type: "warning",
    icon: "exclamation-circle",
    title,
    message,
  });
}

function showMsg(type = "", title = "", message = "", closable = true) {
  let msg = {
    type: type,
    icon:
      type === "error"
        ? "exclamation-triangle"
        : type === "success"
        ? "check"
        : type === "warning"
        ? "exclamation-circle"
        : "",
    title: title,
    message: message,
    position: "",
    closable,
    show: type !== "",
  };

  emitterNotification.next(msg);
}

function subscribeNotification() {
  return emitterNotification.asObservable();
}

export { error, success, warning, subscribeNotification, showMsg };
