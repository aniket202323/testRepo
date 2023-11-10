import { Subject } from "rxjs";

const emitterBreadcrumbEvents = new Subject();

function setBreadcrumbEvents(child) {
  emitterBreadcrumbEvents.next(child);
}

function subscribeBreadcrumbEvents() {
  return emitterBreadcrumbEvents.asObservable();
}

export { subscribeBreadcrumbEvents, setBreadcrumbEvents };
