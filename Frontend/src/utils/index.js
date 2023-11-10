import { success, error } from "../services/notification";
import jsPDF from "jspdf";
import "jspdf-autotable";
import device from "current-device";
import { version } from "../../package.json";
import { ICONS_LIBRARY } from "../components/Icon";
import iconStyle from "../components/Icon/styles.module.scss";

// Missing languages: "da" / "sv" / "it" / "nl" / "zh" / "ja"
const languages = {
  0: "en",
  1: "fr",
  2: "de",
  3: "da",
  5: "es",
  6: "sv",
  7: "it",
  8: "pl",
  9: "ru",
  10: "nl",
  12: "pt",
  13: "zh",
  14: "ja",
  16: "tr",
  18: "ar",
  21: "cs",
};

function requestSuccess(e) {
  success(e?.data || "Execution completed successfully");
}

function requestError(e) {
  let temp = Object();
  let isSecondNotification = e?.isSecondNotification;
  e = e ?? Object({ status: 500 });

  switch (e?.status) {
    case 400:
      temp.title = `Bad Request`;
      temp.message = `The browser send a request that this server could not understand`;
      break;
    case 401:
      temp.title = `Unauthorized`;
      temp.message = `Authorization has been denied for this request`;
      break;
    case 404:
      temp.title = `Not Found`;
      temp.message = `The request URL does not exist or was not found on this server`;
      break;
    case 405:
      temp.title = `Method Not Allowed`;
      temp.message = `The requested resource does not support http method`;
      break;
    case 500:
      temp.title = `Error`;
      temp.message =
        e?.data?.ExceptionMessage ||
        `The server encountered an internal error and was unable to complete your request`;
      break;
    default:
      break;
  }

  error(temp.title, temp.message, isSecondNotification);
}

//#endregion

//#region exports methods

const groupBy = (items, key) =>
  items.reduce(
    (result, item) => ({
      ...result,
      [item[key]]: [...(result[item[key]] || []), item],
    }),
    {}
  );

function generateExportDocument(columns, data, isTasksSelection = false) {
  var document = new jsPDF("landscape");
  let head = columns;
  let body = Array.copy(data);

  let language = localStorage.siteLng || localStorage.i18nextLng;
  let typography = "";
  switch (language) {
    case "ar": {
      typography = "trado";
      break;
    }
    case "ru":
    case "pl": {
      typography = "Arimo-Regular";
      break;
    }
    case "ja":
    case "tr":
    case "zh": {
      typography = "simsun";
      break;
    }
    default: {
      typography = "helvetica";
    }
  }

  if (!isTasksSelection) {
    document.autoTable({
      head: head,
      body: body,
      startY: 5,
      margin: 4,
      rowPageBreak: "auto",
      bodyStyles: { valign: "top" },
      styles: {
        font: typography,
        fontSize: 8,
        cellWidth: "auto",
        minCellWidth: 13,
        cellPadding: 1,
      },
    });
  } else {
    body.forEach((x) => (x.FL3 = "_" + x.FL3));
    body = groupBy(body, "FL3");
    let keys = Object.keys(body);

    keys.forEach((FL3) => {
      if (body[FL3].FL3 !== undefined)
        body[FL3].FL3 = body[FL3].FL3.replace("_", "");
      let groupedData = body[FL3] !== undefined ? body[FL3] : [{}];
      let finalY = document.lastAutoTable.finalY || 5;
      finalY += 5;

      document.autoTable({
        head: [["FL3: " + FL3.replace("_", "")]],
        startY: finalY,
        margin: 4,
        styles: {
          font: typography,
          fillColor: [169, 169, 169],
          fontSize: 8,
          cellWidth: "auto",
          cellPadding: 1,
        },
      });

      let temp = Math.round(finalY);
      if (temp > 200 && temp < 225) {
        finalY = 4;
      }

      document.autoTable({
        head,
        body: groupedData,
        startY: finalY + 5,
        margin: 4,
        showHead: "firstPage",
        styles: {
          font: typography,
          fontSize: 8,
          minCellWidth: 20.6,
          cellWidth: "auto",
          cellPadding: 1,
        },
      });
    });
  }

  return document;
}

function generateExportData(grid) {
  let _array = grid.getDataSource().store()._array;
  let filters = grid.getDataSource()._storeLoadOptions.filter;

  var data = [];
  if (filters !== null && filters !== undefined) {
    var field = "";
    var values = [];
    filters.forEach((f) => {
      field = f[0][0];
      f.forEach((x) => {
        if (x !== "or") values.push(x[2]);
      });
    });
    _array.forEach((item) => {
      for (var i = 0; i < values.length; i++) {
        if (item[field] === values[i]) {
          data.push(item);
        }
      }
    });
  } else data = _array;

  return data;
}

function generateQuickPrint(name, columns, data, isTasksSelection = false) {
  var document = generateExportDocument(columns, data, isTasksSelection);
  document.setProperties({
    title: name,
  });
  var string = document.output("bloburl");
  var iframe =
    "<head><title>gvTasks</title></head> <iframe width='100%' height='100%' style='margin:-10px' src='" +
    string +
    "'></iframe>";

  var x = window.open();
  x.document.open();
  x.document.write(iframe);
  x.document.close();
}

//#endregion

//#region grid filter methods

function filterGridByField(fieldName, fieldValues) {
  let temp = [];

  fieldValues.forEach((value, index) => {
    if (index > 0) temp.push(["or", [fieldName, "=", value]]);
    else temp.push([[fieldName, "=", value]]);
  });
  return temp.flat();
}

//array of object [{fieldName, fieldValues}]
function filterGridByMultipleFields(data) {
  let opshubData = sessionStorage.getItem("OpsHubData");
  if (!opshubData) {
    let filter = [];
    data.forEach((e) => {
      if (e.fieldValues.filter(Boolean).length > 0) {
        let temp = filterGridByField(e.fieldName, e.fieldValues);
        filter.push(temp);
      }
    });
    return filter.length > 0 ? filter : null;
  }
}

//#endregion

function entriesCompare(x, y, deep = false) {
  if (deep) {
    var equals = true;
    for (var key in x) {
      if (x[key] !== y[key]) {
        equals = false;
        break;
      }
    }
    return equals;
  } else return JSON.stringify(x) === JSON.stringify(y);
}

function getHTMLElemByName(attrName) {
  return document.querySelector(`[name=${attrName}]`) ?? "";
}

function getKeySorted(data, key) {
  return data
    .sort((a, b) => a[key] - b[key])
    .map((m) => m[key])
    .join("|");
}

/**
 * Set The IDs of the dynamically generated html components from the className.
 * @param  {Array} - Array of strings with the ID's for that view. If one element is an Object, is:
 * { (String) idContainer (optional), (String") className, (Array of string) ids, (boolean) same (optional) }
 * for that element.
 */
function setIdsByClassName(componentsIds) {
  if (
    componentsIds !== undefined &&
    componentsIds !== null &&
    Array.isArray(componentsIds)
  ) {
    componentsIds.forEach((className) => {
      if (typeof className !== "object") {
        let component = document.getElementsByClassName(className)[0];
        if (component !== undefined) component.setAttribute("id", className);
      } else {
        let components;
        if (className.idContainer !== undefined) {
          let temp = document.getElementById(className.idContainer);
          if (className.class !== undefined)
            components = temp?.getElementsByClassName(className.class);
          else if (className.tagName !== undefined)
            components = temp?.getElementsByTagName(className.tagName);
        } else components = document.getElementsByClassName(className.class);
        if (components !== undefined && components.length !== 0) {
          for (let i = 0; i < components.length; i++) {
            let index = className.same === undefined ? i : 0;
            if (className.ids[index] !== undefined) {
              let name = className.same !== undefined ? "-" + i : "";
              components[i].setAttribute("id", className.ids[index] + name);
            }
          }
        }
      }
    });
  }
}

function isTablet() {
  return device.type === "tablet";
}

function logAppVersion() {
  console.log(
    "%ceCIL v" + version,
    ["background: #003daf", "color: white", "padding: 8px 16px"].join(";")
  );
}

function sortBy(type = "asc", data, field) {
  if (type === "asc")
    data = data.sort(function (a, b) {
      return a[field] > b[field] ? 1 : -1;
    });
  else
    data = data.sort(function (a, b) {
      return a[field] < b[field] ? 1 : -1;
    });
}

function getIcon(name) {
  return ICONS_LIBRARY + `${name}`;
}

function getHtmlElementIcon(name) {
  let elem = document.createElement("i");
  elem.setAttribute("class", ICONS_LIBRARY + `${name} ` + iconStyle.icon);
  return elem;
}

export {
  languages,
  requestSuccess,
  requestError,
  generateExportDocument,
  generateExportData,
  generateQuickPrint,
  filterGridByField,
  filterGridByMultipleFields,
  entriesCompare,
  getHTMLElemByName,
  getKeySorted,
  setIdsByClassName,
  isTablet,
  logAppVersion,
  groupBy,
  sortBy,
  getIcon,
  getHtmlElementIcon,
};
