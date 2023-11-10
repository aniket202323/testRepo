import React, { PureComponent } from "react";
import Button from "../../../../components/Button";
import { SelectBox } from "devextreme-react/ui/select-box";
import DataGrid from "../../../../components/DataGrid";
import { Column, Selection } from "devextreme-react/ui/data-grid";
import Popup from "../../../../components/Popup";
import Input from "../../../../components/Input";
import DateBox from "devextreme-react/ui/date-box";
import { displayPreload } from "../../../../components/Framework/Preload";
import { CustomViewDialog } from "../../../../components/CustomView";
import List, { ItemDragging } from "devextreme-react/list";
import { custom } from "devextreme/ui/dialog";
import { renderToString } from "react-dom/server";
import { gridColumns } from "../options";
import { getIcon, setIdsByClassName, sortBy } from "../../../../utils";
import { getProfile } from "../../../../services/auth";
import {
  getPrompts,
  saveTasksSelection,
  getTaskInfo,
  setTasksValues,
  addComments,
  updateComments,
} from "../../../../services/tasks";
import dayjs from "dayjs";
import { CL_TASKS_STATE } from "../../../../utils/constants";
import nav from "../tabs.scss";
import styles from "../styles.module.scss";
import { getTourMapImage } from "../../../../services/tourStops";
import Icon from "../../../../components/Icon";
import icons from "../../../../resources/icons";
import { TransformWrapper, TransformComponent } from "react-zoom-pan-pinch";
import { warning } from "../../../../services/notification";
import { ViewImagePopup } from "./common";

class ListItems extends PureComponent {
  constructor(props) {
    super(props);

    this.refList = React.createRef();
    this.refFieldsList = React.createRef();
    this.refPostponeDialog = React.createRef();
    this.refDtpPostponedTask = React.createRef();
    this.refGridTourMaps = React.createRef();
    this.refInfoGrid = React.createRef();

    this.state = {
      promps: [],
      taskInfoDS: [],
      showInformationTable: false,
      data: [],
      fields: [],
      fieldsCaption: [],
      fieldsCol1: [],
      fieldsCol2: [],
      fieldsCol3: [],
      selectedItems: [],
      selectedFields: [],
      lastFilter: "",
      pendingSum: 0,
      lateSum: 0,
      defectSum: 0,
      okSum: 0,
      CLSum: 0,
      showMainFields: false,
      showCustomViewDialog: false,
      showPostponeTaskDialog: false,
      sortBy: { value: "Due Date", type: "asc" },
      chooserOption: true,
      showTourMapLinks: false,
      tourMapLink: "",
      TourDesc: "",
      noTourStopTasksMessage: "",
      isExpanded: false,
      selectedCustomView: {},
      originalData: [],
      isCompletedAll: false,
      tourMaps: [],
      disableCompleteAll: true,
      showHSE: false,
      showPQF: false,
      showQType: false,
      commentWasUpdated: false,
      showImagePopup: false,
    };
  }

  componentDidMount = () => {
    getPrompts().then((response) => this.setState({ promps: response }));
    this.setInitialColumns();
  };

  componentDidUpdate = (prevProps, prevState) => {
    let { lastFilter, isExpanded, sortBy, originalData } = this.state;
    if (prevProps.data !== this.props.data) {
      let data = Object.assign([], this.props.data);
      this.props.data.forEach((task) =>
        originalData.push(Object.assign({}, task))
      );

      this.setState(
        {
          dataFiltered: data,
          originalData,
          data,
          selectedItems: [],
          lastFilter: "",
          noTourStopTasksMessage: "",
          tourMaps: this.props.tourMaps,
        },
        () => {
          lastFilter !== "" && lastFilter !== "Ok"
            ? this.applyCurrentResultFilter(lastFilter)
            : displayPreload(false);
          setTimeout(() => {
            this.sortTasks();
          }, 250);
          this.updateQuantitiesTasks();
          isExpanded && this.accordionHandler(null, true);

          this.disableCompleteAll();
        }
      );
      this.handlerClickLoadMoreTasksButton();
    } else {
      if (prevState.lastFilter !== lastFilter && lastFilter !== "") {
        this.applyCurrentResultFilter(lastFilter);
      }
      if (prevState.selectedItems !== this.state.selectedItems) {
        this.refreshSelectedItems();
      }
      let { value, type } = sortBy;
      let { value: prevValue, type: prevType } = prevState.sortBy;
      if (value !== prevValue || type !== prevType) {
        this.refList?.current?.instance.reload();
      }
    }
  };

  moveSpecificationsToEnd = (columns) => {
    // eslint-disable-next-line
    ["U_Reject", "Target", "L_Reject"].map((field) => {
      let _field = columns.find((x) => x.dataField === field);
      _field.visibility = true;
      columns = columns.concat(
        columns.splice(columns.map((x) => x.dataField).indexOf(field), 1)
      );
    });
    return columns;
  };

  disableCompleteAll = () => {
    let refList = this.refList.current?.instance;
    let dataList = refList?._dataSource?._items;
    let disableCompleteAll =
      dataList?.filter((z) => ["Late", "Pending"].includes(z.CurrentResult))
        .length === 0;
    this.setState({ disableCompleteAll });
  };

  setInitialColumns = () => {
    let fields = [];
    let fieldsCaption = [];
    let selectedFields = this.state.selectedFields;
    let columns = [...gridColumns(this.props.t)];
    sortBy("asc", columns, "caption");
    columns = this.moveSpecificationsToEnd(columns);
    columns = columns.filter(
      (x) =>
        ![
          "",
          "ColInfo",
          "ColDoc",
          "Defects",
          "CurrentResult",
          "ExternalLink",
          "VarDesc",
          "NbrDefects",
          "IsHSE",
          "PrimaryQFactor",
          "QFactorType",
        ].includes(x.dataField) && x.showInColumnChooser
    );
    columns.forEach((x, index) => {
      fields.push({
        dataField: x.dataField,
        caption: x.caption,
        visibility: x.visibility,
        order: index,
      });
      fieldsCaption.push(x.caption);
      if (
        x.visibility ||
        ["L_Reject", "Target", "U_Reject"].includes(x.caption)
      )
        selectedFields.push(x.caption);
    });

    // remove fields from column chooser
    fieldsCaption = fieldsCaption.filter(
      (x) =>
        !["is hse?", "hazards", "primary q-factor", "comment"].includes(
          x.toLowerCase()
        )
    );

    this.setState(
      {
        fields,
        selectedFields,
        fieldsCaption,
        okSum: 0,
      },
      () => {
        this.buildColumns(false);
      }
    );
  };

  handlerShowHideScrollToTopButton = () => {
    let list = document
      .getElementById("lstTasksSelection")
      .getElementsByClassName("dx-scrollable-container")[0];
    let botonScrollToTop = document.getElementById("btnScrollToTop");
    if (botonScrollToTop !== null && list !== null) {
      botonScrollToTop.style.display = "none";
      list.addEventListener("scroll", () =>
        this.onScrollListview(list, botonScrollToTop)
      );
    }
  };

  onScrollListview = (list, botonScrollToTop) => {
    if (list.scrollTop !== 0) botonScrollToTop.style.display = "block";
    else botonScrollToTop.style.display = "none";
  };

  updateQuantitiesTasks = () => {
    let data = [...this.state.dataFiltered];
    let pendingSum = data.filter((x) =>
      this.getUserPrompt(x.CurrentResult).includes("Pending")
    ).length;
    let lateSum = data.filter((x) =>
      this.getUserPrompt(x.CurrentResult).includes("Late")
    ).length;
    let defectSum = data.filter((x) =>
      this.getUserPrompt(x.CurrentResult).includes("Defect")
    ).length;
    let okSum = data.filter((x) =>
      this.getUserPrompt(x.CurrentResult).includes("Ok")
    ).length;
    let CLSum = data.filter((x) => x.EventSubtypeDesc.includes("CL")).length;
    this.setState({ pendingSum, lateSum, defectSum, okSum, CLSum });
  };

  handlerClickLoadMoreTasksButton = () => {
    setTimeout(() => {
      let btnMoreTasks = document.getElementsByClassName(
        "dx-list-next-button"
      )[0];
      btnMoreTasks !== undefined &&
        btnMoreTasks.addEventListener("click", () =>
          this.refreshSelectedItems()
        );
    }, 1000);
  };

  getUserPrompt = (value) => {
    return (
      this.state.promps?.find((t) => t.ServerPrompt === value)?.UserPrompt ?? ""
    );
  };

  getServerPrompt = (value) => {
    return (
      this.state.promps?.find((t) => t.UserPrompt === value)?.ServerPrompt ?? ""
    );
  };

  getTasksStateValues = (value) => {
    value = this.getUserPrompt(value);

    const { promps } = this.state;

    if (value.includes("Defect")) {
      return promps.filter((t) => t.UserPrompt.includes("Defect"));
    }

    if (value.includes("Ok")) {
      return promps.filter(
        (t) => t.UserPrompt.includes("Defect") || t.UserPrompt.includes("Ok")
      );
    }

    if (value.includes("Late")) {
      return promps.filter(
        (t) =>
          t.UserPrompt.includes("Defect") ||
          t.UserPrompt.includes("Ok") ||
          t.UserPrompt.includes("Late")
      );
    }

    if (value.includes("Pending")) {
      return promps.filter(
        (t) =>
          t.UserPrompt.includes("Defect") ||
          t.UserPrompt.includes("Ok") ||
          t.UserPrompt.includes("Pending")
      );
    }
  };

  onClickCellInfo = (dataSelected) => {
    const { t } = this.props;
    let _temp = [];
    let TestId = dataSelected.TestId;

    let fields = [
      "TestId",
      "VarDesc",
      "LongTaskName",
      "TaskAction",
      "TaskId",
      "FL1",
      "FL2",
      "FL3",
      "FL4",
      "TaskFreq",
      "TaskType",
      "EntryOn1",
      "Criteria",
      "Hazards",
      "Method",
      "PPE",
      "Tools",
      "Lubricant",
    ];

    displayPreload(true);
    getTaskInfo(TestId).then((data) => {
      data["VarDesc"] = data.TaskName;
      data["TaskFreq"] = data.TaskFrequency;
      data["PPE"] = data.Ppe;
      if (data.EntryOn1 !== "" && data.EntryOn1 !== null)
        data["EntryOn1"] = dayjs(data.EntryOn1).format("MM-DD-YYYY HH:mm:ss");

      Object.keys(data).forEach((key) => {
        if (fields.includes(key)) {
          let column = gridColumns(t)
            .filter((column) => column.caption)
            .find((col) => col.dataField === key);
          if (column !== undefined) {
            _temp.push({
              order: fields.indexOf(key),
              caption: column.caption,
              value: data[key],
            });
          }
        }
      });

      _temp = _temp.sort((a, b) => a.order - b.order);
      this.setState({ taskInfoDS: _temp, showInformationTable: true }, () =>
        displayPreload(false)
      );
    });
  };

  onClickCellComment = (data) => {
    const { t } = this.props;
    let { selectedItems } = this.state;
    const { TestId } = data;
    let dialog = custom({
      title: t("Task Comment"),
      messageHtml: renderToString(
        <form className={styles.commentDialogMobility}>
          <Input
            id="txtTaskComment"
            name="txtTaskComment"
            type="text"
            border
            defaultValue={data.CommentInfo}
          />
        </form>
      ),
      buttons: [
        {
          text: t("Save"),
          type: "default",
          onClick: () => Object({ save: true }),
        },
        { text: t("Cancel") },
      ],
      dragEnabled: false,
    });
    dialog.show().then((dialogResult) => {
      let value = document.getElementById("txtTaskComment").value;
      if (dialogResult?.save && value !== data.CommentInfo) {
        !selectedItems.includes(TestId) && selectedItems.push(TestId);
        let btnCommnet = document.getElementById("btnComment-" + TestId);
        btnCommnet.title = value;
        data.CommentInfo = value;
        this.taskItemRender(data);
        this.setState(
          {
            selectedItems,
            commentWasUpdated: true,
          },
          () => {
            this.refreshSelectedItems(true);
          }
        );
      }
    });
    setTimeout(() => {
      setIdsByClassName([
        {
          class: "dx-overlay-content dx-popup-normal dx-resizable",
          ids: ["popTaskCommentMobility"],
        },
        {
          idContainer: "popTaskCommentMobility",
          class: "dx-button dx-dialog-button",
          ids: [
            "btnSaveTaskCommentTasksSelection",
            "btnCancelTaskCommentTasksSelection",
          ],
        },
      ]);
    }, 500);
  };

  onClickCellMove = (data) => {
    this.setState({ showPostponeTaskDialog: true }, () => {
      setTimeout(() => {
        var date = data.ScheduleTime;
        var refdtp = this.refDtpPostponedTask.current?.instance;
        var refPostponeDialog = this.refPostponeDialog.current?.instance;
        var txtCurrentTime = document.querySelector("[name=txtCurrentTime]");
        txtCurrentTime.textContent = date;
        txtCurrentTime.style.display = "block";

        refPostponeDialog.data = { VarId: data.VarId };
        refdtp.option("value", dayjs(date));
      }, 500);
    });
  };

  onAceptPostpone = () => {
    let data = this.refPostponeDialog.current?.instance.data;
    let list = this.refList.current.instance;
    let selectedItems = this.state.selectedItems;

    var value = this.refDtpPostponedTask.current.instance._changedValue;
    let item = list._dataSource._items.find(
      (item) => item.TestId === data.TestId
    );

    if (!dayjs(item.ScheduleTime).isSame(dayjs(value))) {
      let element = document.getElementById(data.TestId);
      item.ScheduleTime = dayjs(value).format("MM-DD-YYYY HH:mm");
      !selectedItems.includes(item.TestId) && selectedItems.push(item.TestId);
      element.setAttribute("selectedcard", "true");
      element.style.backgroundColor = "#fff289";
      list._refresh();
      this.refreshSelectedItems();
    }

    this.setState({ showPostponeTaskDialog: false });
  };

  onSaveSelectedTasks = () => {
    let editedData = [];
    let refList = this.refList.current.instance;
    let data = refList.getDataSource()._store._array;
    let { selectedItems, commentWasUpdated, originalData } = this.state;
    let id_token = sessionStorage.getItem("OpsHubToken");
    if (selectedItems.length) {
      selectedItems.forEach((t) => {
        let task = data.find((y) => y.TestId === t);
        if (task !== undefined) editedData.push(task);
      });
      displayPreload(true);
      saveTasksSelection(editedData).then(() => {
        let clTasks = this.filterOnlyCLTasks(editedData);
        setTimeout(() => {
          if (clTasks.length && id_token) {
            let valueWasUpdated =
              JSON.stringify(originalData.map((x) => x.CurrentResult)) !==
              JSON.stringify(data.map((x) => x.CurrentResult));
            if (valueWasUpdated)
              setTasksValues(clTasks).then(() => {
                if (!commentWasUpdated) this.props.handlerData(true);
              });
            let tasksAddinComments = clTasks.filter((t) => t.CommentId === -1);
            let tasksUpdatingComments = clTasks.filter(
              (t) => t.CommentId !== -1
            );

            if (tasksAddinComments.length)
              addComments(tasksAddinComments).then(() => {
                if (!tasksUpdatingComments.length && commentWasUpdated)
                  this.refreshTasks();
              });
            if (tasksUpdatingComments.length)
              updateComments(tasksUpdatingComments).then(() => {
                this.refreshTasks();
              });

            if (!commentWasUpdated) displayPreload(false);
          } else displayPreload(false);
        }, 250);

        this.setState({ selectedItems: [] }, () => this.refreshSelectedItems());
      });
    }
  };

  refreshTasks = () => {
    setTimeout(() => {
      this.setState({ commentWasUpdated: false }, () =>
        this.props.handlerData(true)
      );
    }, 250);
  };

  filterOnlyCLTasks = (data) => {
    return data.filter((x) => x.EventSubtypeDesc !== "eCIL");
  };

  onClickRefreshTails = () => {
    this.props.handlerData();
  };

  onCompleteAllTasks = () => {
    let refList = this.refList.current.instance;
    let dataList = refList._dataSource._items;
    let { selectedItems, okSum, lateSum, pendingSum, originalData } =
      this.state;

    let modifiedTasks = [];
    displayPreload(true);
    if (!this.state.isCompletedAll) {
      dataList.forEach((task) => {
        let CurrentResult_EN = this.getUserPrompt(task.CurrentResult);
        let isCLTask = task.EventSubtypeDesc.includes("CL");
        if (
          !CurrentResult_EN.includes("Defect") &&
          !CurrentResult_EN.includes("Ok") &&
          !isCLTask
        ) {
          task.CurrentResult = this.getServerPrompt("Ok");
          !selectedItems.includes(task.TestId) &&
            selectedItems.push(task.TestId);
          modifiedTasks.push(task);
          okSum += 1;
          if (CurrentResult_EN.includes("Late")) lateSum -= 1;
          if (CurrentResult_EN.includes("Pending")) pendingSum -= 1;
        }
      });
    } else {
      // second time
      dataList.forEach((task) => {
        let isCLTask = task.EventSubtypeDesc.includes("CL");
        let originalValue = [...originalData].find(
          (t) => t.TestId === task.TestId
        )?.CurrentResult;
        let original_EN = this.getUserPrompt(originalValue);
        if (!originalValue) return;
        if (
          this.getUserPrompt(task.CurrentResult).includes("Ok") &&
          !original_EN.includes("Defect") &&
          !isCLTask
        ) {
          task.CurrentResult = originalValue;
          modifiedTasks.push(task);
          okSum -= 1;
          if (original_EN.includes("Late")) lateSum += 1;
          if (original_EN.includes("Pending")) pendingSum += 1;
        }
      });
      selectedItems = [];
    }

    setTimeout(() => {
      refList._refresh();
      this.setState(
        {
          selectedItems,
          okSum,
          lateSum,
          pendingSum,
          isCompletedAll: !this.state.isCompletedAll,
        },
        () => {
          this.refreshSelectedItems();
          this.state.lastFilter !== "" &&
            this.applyCurrentResultFilter(this.state.lastFilter);
          displayPreload(false);
        }
      );
    }, 800);
  };

  refreshSelectedItems = (isFromComment = false) => {
    let { selectedItems } = this.state;
    setTimeout(() => {
      selectedItems.forEach((id) => {
        let card = document.getElementById(id);
        if (card) {
          let CurrentResult = card?.getAttribute("value");
          if (CurrentResult !== "Defect" || isFromComment) {
            card.setAttribute("selectedcard", "true");
            card.style.backgroundColor = "#fff289";
          }
        }
      });
      // let selectableItems = this.state.selectableItems;
      //   selectableItems.forEach((id) => {
      //     let elem = document.getElementById(id);
      //     if (elem) {
      //       elem.setAttribute("selectedcard", "false");
      //     }
      //   });
    }, 250);
  };

  buildColumns = (wasFieldsChanged, columnsCant = 3) => {
    let fields = this.state.fields;
    let fieldsCol1 = [];
    let fieldsCol2 = [];
    let fieldsCol3 = [];
    if (wasFieldsChanged) {
      let refFieldsList = this.refFieldsList.current?.instance;
      let fieldsCaption = refFieldsList._selection.options.selectedItems;
      fields.forEach((x) => (x.visibility = false));
      fieldsCaption.forEach((x) => {
        fields.find((y) => y.caption === x).visibility = true;
      });
    }

    setTimeout(() => {
      let fieldsVisibles = [...fields.filter((item) => item.visibility)];
      let fieldsPerColumn = fieldsVisibles.length;
      if (fieldsPerColumn % 3 === 1) fieldsPerColumn += 2;
      if (fieldsPerColumn % 3 === 2) fieldsPerColumn += 1;
      fieldsPerColumn = parseInt(fieldsPerColumn / columnsCant);

      for (let i = 0; i < fieldsPerColumn; i++) {
        fieldsVisibles[i] && fieldsCol1.push(fieldsVisibles[i]);
        fieldsVisibles[i + fieldsPerColumn] !== undefined &&
          columnsCant > 1 &&
          fieldsCol2.push(fieldsVisibles[i + fieldsPerColumn]);
        fieldsVisibles[i + fieldsPerColumn * 2] !== undefined &&
          fieldsVisibles[i + fieldsPerColumn * 2] !== undefined &&
          columnsCant === 3 &&
          fieldsCol3.push(fieldsVisibles[i + fieldsPerColumn * 2]);
      }

      if (wasFieldsChanged) {
        this.setState({
          fieldsCol1,
          fieldsCol2,
          fieldsCol3,
          fields,
          showMainFields: false,
          columnsCant,
        });
      } else {
        this.setState({
          fieldsCol1,
          fieldsCol2,
          fieldsCol3,
          columnsCant,
        });
      }
    }, 500);
  };

  selectCardItem = (Item, sboItem, isCL = true, isInput = false) => {
    let selectedItems = this.state.selectedItems;
    let element = document.getElementById(Item.TestId);
    element.setAttribute("selectedcard", "true");
    element.style.backgroundColor = "#fff289";
    !selectedItems.includes(Item.TestId) && selectedItems.push(Item.TestId);

    if (!isCL) {
      sboItem.element.className =
        styles.headerDropdown + " " + styles[this.getUserPrompt(sboItem.value)];
      sboItem.element.setAttribute("style", "width: 155px !important");
    } else {
      let container = isInput === false ? sboItem.element : sboItem;
      let options = { value: sboItem.value };
      let val = Item;
      let L_Reject = val?.L_Reject;
      let Target = val?.Target;
      let U_Reject = val?.U_Reject;
      let valueEntered = options.value;
      let VarDataType = val?.VarDataType;
      let paramSpecSetting = parseInt(localStorage.getItem("paramSpecSetting"));
      let type = "";

      if (valueEntered !== "")
        if ("Float Integer".includes(VarDataType)) {
          L_Reject = L_Reject ? parseFloat(L_Reject) : null;
          Target = Target ? parseFloat(Target) : null;
          U_Reject = U_Reject ? parseFloat(U_Reject) : null;
          if (
            (L_Reject && !Target && !U_Reject) ||
            (L_Reject && Target && !U_Reject)
          ) {
            if (paramSpecSetting === 1)
              type = valueEntered > L_Reject ? "inTarget" : "outTarget";
            else if (paramSpecSetting === 0)
              type = valueEntered >= L_Reject ? "inTarget" : "outTarget";
          } else if (
            (!L_Reject && !Target && U_Reject) ||
            (!L_Reject && Target && U_Reject)
          ) {
            if (paramSpecSetting === 1)
              type = valueEntered < U_Reject ? "inTarget" : "outTarget";
            else if (paramSpecSetting === 0)
              type = valueEntered <= U_Reject ? "inTarget" : "outTarget";
          } else if (
            (L_Reject && Target && U_Reject) ||
            (L_Reject && !Target && U_Reject)
          ) {
            if (paramSpecSetting === 1)
              type =
                valueEntered > L_Reject && valueEntered < U_Reject
                  ? "inTarget"
                  : "outTarget";
            else if (paramSpecSetting === 0)
              type =
                valueEntered >= L_Reject && valueEntered <= U_Reject
                  ? "inTarget"
                  : "outTarget";
          } else if (!L_Reject && Target && !U_Reject) {
            type = valueEntered === Target ? "inTarget" : "outTarget";
          }
        } else if ("String Logical Yes/No Pass/Fail".includes(VarDataType)) {
          type = valueEntered === Target ? "inTarget" : "outTarget";
        }
      container.setAttribute("style", CL_TASKS_STATE[type]);
    }
  };

  resetCLSpecValuesAndSetTitle = (row) => {
    let title = "";
    let keys = ["VarDesc", "L_Reject", "Target", "U_Reject"];
    keys.forEach((key) => {
      let elem = document.getElementById(key);
      if (elem) document.getElementById(key).textContent = "";
      if (key !== "VarDesc") title = this.setTooltip(title, row, key);
    });
    let val =
      `CL values specifications:
` + title;
    title = title !== "" ? val : "No specifications for CL";
    title =
      title.slice(title.length - 2, title.length - 1) === "|"
        ? title.slice(0, title.length - 3)
        : title;
    return title;
  };

  setTooltip = (title, row, field) => {
    let shortTitle = field.includes("L_")
      ? "Low R"
      : field.includes("U_")
      ? "Upper R"
      : "Target";
    title += row[field] ? `${shortTitle}: ` + row[field] + ` | ` : "";
    return title;
  };

  taskItemRender = (item) => {
    const { t } = this.props;
    let { fieldsCol1, fieldsCol2, fieldsCol3, columnsCant, isExpanded } =
      this.state;
    let globalAccessLevel = getProfile().GlobalAccessLevel;
    let disabledAccess = globalAccessLevel === 1;
    let isCL = item.EventSubtypeDesc.includes("CL");
    let valueEN = !isCL
      ? this.getUserPrompt(item.CurrentResult)
      : item.CurrentResult;
    let VarDataType = item.VarDataType;
    let title = "";
    if (isCL) title = this.resetCLSpecValuesAndSetTitle(item);
    let hasDefect = item.NbrDefects > 0;
    let refList = this.refList.current.instance.getDataSource()._store._array;

    return (
      <div
        id={item.TestId}
        className={styles.taskItemContainer}
        value={
          valueEN ||
          document.getElementById("input_" + item.TestId)?.getAttribute("value")
        }
      >
        <div
          className={isExpanded ? styles.taskHeaderExpanded : styles.taskHeader}
        >
          <h3 style={{ width: isExpanded ? "100%" : "" }}>{item.VarDesc}</h3>
          <div className={styles.filterButtonsLeft}>
            {hasDefect && (
              <Button
                id={"btnDefect-" + item.TestId}
                classes={styles.btnItemTaskButton}
                hint={t("Defect")}
                text={isCL ? "" : item.NbrDefects}
                icon={icons.gridDefect}
                style={{ width: "40px" }}
                onClick={() => {
                  this.props.handlerDefects();
                  var data = Object.assign({}, item);
                  this.props.refDefects.setData(data);
                }}
              />
            )}
            <Button
              id={"btnComment-" + item.TestId}
              classes={styles.btnItemTaskButton}
              hint={t(item.CommentInfo || "Comment")}
              icon={item.CommentInfo === "" ? "plus" : "pencil"}
              onClick={() => this.onClickCellComment(item)}
              disabled={disabledAccess}
            />
            {item.Fixed === "0" &&
              item.TaskFreq.includes("D") &&
              valueEN !== "Defect" && (
                <Button
                  id={"btnPostponed-" + item.TestId}
                  classes={styles.btnItemTaskButton}
                  hint={t("PostPoned")}
                  icon={icons.gridPostponed}
                  // imgsrc={icons.gridPostponed}
                  onClick={() => this.onClickCellMove(item)}
                  disabled={globalAccessLevel !== 3 && globalAccessLevel !== 4}
                />
              )}

            {!isCL ? (
              <SelectBox
                id={"sboTaskSelectioniPad-" + item.TestId}
                defaultValue={item.CurrentResult}
                dataSource={this.getTasksStateValues(item.CurrentResult)}
                displayExpr="LangPrompt"
                valueExpr="ServerPrompt"
                className={styles.headerDropdown + " " + styles[valueEN]}
                disabled={disabledAccess}
                onFocusIn={(e) => {
                  setTimeout(() => {
                    e.component.open();
                  }, 25);
                }}
                style={{ width: "155px" }}
                onValueChanged={(sboItem) => {
                  let value = this.getUserPrompt(sboItem.value);
                  if (value.includes("Defect")) {
                    this.refList.current.instance._refresh();
                    this.props.handlerDefects();
                    var data = Object.assign({}, item);
                    data.CurrentResult = this.getServerPrompt(value);
                    this.props.refDefects.setData(data);
                    this.refreshSelectedItems();
                  } else {
                    let previousValue = sboItem.previousValue;
                    let previousValue_EN = this.getUserPrompt(previousValue);
                    item.CurrentResult = sboItem.value;

                    // "Ok" filter
                    if (previousValue_EN.includes("Late"))
                      previousValue = "lateSum";
                    if (previousValue_EN.includes("Pending"))
                      previousValue = "pendingSum";

                    if (value.includes("Ok")) {
                      let okSum = this.state.okSum + 1;
                      this.setState({
                        okSum,
                        [previousValue]: this.state[previousValue] - 1,
                      });
                    }
                    this.selectCardItem(item, sboItem, false);
                  }
                }}
              />
            ) : "Yes/No Pass/Fail Logical".includes(VarDataType) ? (
              <>
                <span custom-tooltip={title} class="_tooltip_click_CL">
                  <SelectBox
                    defaultValue={
                      item.CurrentResult ||
                      document
                        .getElementById(item.TestId)
                        ?.getAttribute("value")
                    }
                    dataSource={
                      "Yes/No".includes(VarDataType)
                        ? [{ val: "Yes" }, { val: "No" }]
                        : "Pass/Fail".includes(VarDataType)
                        ? [{ val: "Pass" }, { val: "Fail" }]
                        : "Logical".includes(VarDataType)
                        ? [{ val: "1" }, { val: "0" }]
                        : []
                    }
                    disabled={globalAccessLevel === 1 ? true : false}
                    displayExpr="val"
                    valueExpr="val"
                    style={{ width: "155px" }}
                    onFocusIn={(e) => {
                      setTimeout(() => {
                        e.component.open();
                      }, 25);
                    }}
                    onValueChanged={(rowData) => {
                      let value = rowData.value;
                      var data = Object.assign({}, item);
                      data.CurrentResult = value;

                      document
                        .getElementById(item.TestId)
                        ?.setAttribute("value", value);

                      this.selectCardItem(item, rowData);
                    }}
                  />
                </span>
              </>
            ) : (
              <>
                <td custom-tooltip={title} class="_tooltip">
                  <input
                    id={"input_" + item.TestId}
                    type="text"
                    defaultValue={
                      document
                        .getElementById("input_" + item.TestId)
                        ?.getAttribute("value") || item.CurrentResult
                    }
                    style={{
                      background:
                        item.CurrentResult && item.Target
                          ? item.CurrentResult >= Number(item.L_Reject) &&
                            item.CurrentResult <= Number(item.U_Reject)
                            ? "#1BFF00"
                            : "red"
                          : "white",
                      color:
                        item.CurrentResult && item.Target
                          ? item.CurrentResult >= Number(item.L_Reject) &&
                            item.CurrentResult <= Number(item.U_Reject)
                            ? "black"
                            : "white"
                          : "black",
                    }}
                    onClick={() => {
                      let input = document.getElementById(
                        "input_" + item.TestId
                      );
                      input.style.backgroundColor = "white";
                      input.style.color = "black";
                    }}
                    onBlur={() => {
                      let input = document.getElementById(
                        "input_" + item.TestId
                      );
                      if (item?.CurrentResult !== input.value) {
                        let varDataType = item.VarDataType;
                        let val = input.value;
                        let values = val?.split(".");
                        let hasDecimals = values?.length === 2;

                        if (varDataType === "Float") {
                          if (hasDecimals) {
                            let decimals = values[1];
                            if (decimals.length >= 2 && decimals !== "00")
                              val = parseFloat(val);
                          } else val = parseInt(val).toFixed(2);
                          val = isNaN(parseFloat(val)) ? input.value : val;
                        }

                        input.value = val;
                        refList.find(
                          (t) => t.TestId === item.TestId
                        ).CurrentResult = val;

                        document
                          .getElementById("input_" + item.TestId)
                          .setAttribute("value", val);

                        this.selectCardItem(item, input, true, true);
                      }
                    }}
                  />
                </td>
              </>
            )}
          </div>
        </div>
        <div className={styles.taskDescription}>
          <div className={styles.columnsContainer}>
            <div className={!isExpanded ? styles.columnLeft : ""}>
              {fieldsCol1.length !== 0 &&
                fieldsCol1.map((col) => {
                  let value = item[col.dataField];
                  // eslint-disable-next-line
                  if (value === -1 || value === 0 || value === "") return;
                  return (
                    <div key={col.dataField}>
                      <b>{t(col.caption)}: </b>
                      {typeof value !== "boolean" ? (
                        value
                      ) : (
                        <input
                          id={"chk" + col.dataField + "-" + item.TestId}
                          type="checkbox"
                          checked={value}
                          disabled
                        />
                      )}
                      <br />
                    </div>
                  );
                })}
            </div>
            <div className={styles.columnCenter}>
              {fieldsCol2.length !== 0 &&
                columnsCant > 1 &&
                fieldsCol2.map((col) => {
                  let value = item[col.dataField];
                  // eslint-disable-next-line
                  if (value === -1 || value === 0 || value === "") return;
                  return (
                    <div key={col.dataField}>
                      <b>{t(col.caption)}: </b>
                      {typeof value !== "boolean" ? (
                        value
                      ) : (
                        <input
                          id={"chk" + col.dataField + "-" + item.TestId}
                          type="checkbox"
                          checked={value}
                          disabled
                        />
                      )}
                      <br />
                    </div>
                  );
                })}
            </div>
            <div className={styles.columnRight}>
              {fieldsCol3.length !== 0 &&
                columnsCant === 3 &&
                fieldsCol3.map((col) => {
                  let value = item[col.dataField];
                  // eslint-disable-next-line
                  if (value === -1 || value === 0 || value === "") return;
                  return (
                    <div key={col.dataField}>
                      <b>{t(col.caption)}: </b>
                      {typeof value !== "boolean" ? (
                        <span className={styles[col.dataField]}>{value} </span>
                      ) : (
                        <input
                          id={"chk" + col.dataField + "-" + item.TestId}
                          type="checkbox"
                          checked={value}
                          disabled
                        />
                      )}
                      <br />
                    </div>
                  );
                })}
            </div>
          </div>
          {/* </div> */}
        </div>
        <div className={styles.bottomButtonsContainer}>
          {item.IsHSE === true && (
            <Button
              id={"btnIsHSE" + item.TestId}
              classes={styles.btnItemTaskButton}
              icon={"helmet-safety"}
              hint={t("Is HSE?")}
              onClick={() => this.setState({ showHSE: true })}
              iconStyle={{ color: "#ff5e00" }}
            />
          )}
          {item.PrimaryQFactor === "Yes" && (
            <Button
              id={"btnPrimary" + item.TestId}
              classes={styles.btnItemTaskButton}
              icon={"flask"}
              iconStyle={{ color: "red" }}
              hint={t("Primary Q-Factor")}
              onClick={() => this.setState({ showPQF: true })}
            />
          )}
          {item.QFactorType && (
            <Button
              id={"btnQfactor" + item.TestId}
              classes={styles.btnItemTaskButton}
              icon={"q"}
              iconStyle={{ color: "#012169" }}
              hint={t("Quality Factor")}
              onClick={() => this.setState({ showQType: true })}
            />
          )}
          <Button
            id={"btnInfoTask" + item.TestId}
            classes={styles.btnItemTaskButton}
            icon="circle-info"
            hint={t("Task information")}
            onClick={() => this.onClickCellInfo(item)}
          />
          {item.ExternalLink !== "" && (
            <Button
              id={"btnDocument" + item.TestId}
              classes={styles.btnItemTaskButton}
              hint={t("Document")}
              icon="file"
              onClick={() => window.open(item.ExternalLink, "_blank")}
            />
          )}
        </div>
      </div>
    );
  };

  onItemCardClick = (item) => {
    let { originalData, okSum, pendingSum, lateSum, selectedItems } =
      this.state;
    let refList = this.refList.current.instance;
    let dataList = refList._dataSource._store._array;
    let testId = item.itemData.TestId;

    let tasgs = ["IMG", "INPUT", "I"];
    let classNames = ["dx-dropdowneditor-icon", "dx-texteditor-input"];
    if (
      !tasgs.includes(item.event.target.tagName) &&
      !classNames.includes(item.event.target.className)
    ) {
      let element = document.getElementById(item.itemData.TestId);
      if (!element) return;
      if (element.hasAttribute("selectedcard")) {
        let toogleSelect = element.getAttribute("selectedcard");

        if (toogleSelect === "true") {
          let isDeselecting = selectedItems.includes(testId);
          let previousValue = originalData.find(
            (y) => y.TestId === testId
          )?.CurrentResult;

          let isCL = item.itemData.EventSubtypeDesc !== "eCIL";

          if (isDeselecting && isCL) {
            selectedItems.splice(selectedItems.indexOf(testId), 1);

            let originalValue = [...this.state.originalData].find(
              (t) => t.TestId === testId
            )?.CurrentResult;

            dataList.find((x) => x.TestId === testId).CurrentResult =
              originalValue;
          }

          let previousValue_EN = this.getUserPrompt(previousValue);

          if (
            (item.itemData.CurrentResult !== previousValue || isDeselecting) &&
            !isCL
          ) {
            if (previousValue_EN.includes("Late")) lateSum += 1;
            if (previousValue_EN.includes("Pending")) pendingSum += 1;
            if (!previousValue_EN.includes("Defect")) okSum -= 1;
            dataList.find((x) => x.TestId === testId).CurrentResult =
              previousValue;

            selectedItems.splice(selectedItems.indexOf(testId), 1);

            element.style.backgroundColor = "#FFF";
            element.setAttribute("selectedcard", false);
          }

          this.setState(
            {
              okSum,
              lateSum,
              pendingSum,
              selectedItems,
              isCompletedAll: false,
            },
            () => {
              this.refreshSelectedItems();
              refList._refresh();
            }
          );
        }
      }
    }
  };

  onClickFilterButton = (value) => {
    let { data, dataFiltered, lastFilter, isExpanded } = this.state;
    if (!dataFiltered.length) return;
    this.setState(
      {
        lastFilter: lastFilter === value ? "" : value,
      },
      () => {
        if (lastFilter === value) {
          displayPreload(true);
          setTimeout(() => {
            let refList = this.refList.current.instance;
            refList._dataSource._store._array = isExpanded
              ? dataFiltered
              : data;
            refList.reload();
            displayPreload(false);
          }, 250);
        }
        this.refreshSelectedItems();
        setTimeout(() => {
          this.disableCompleteAll();
        }, 350);
      }
    );
  };

  applyCurrentResultFilter = (value) => {
    displayPreload(true);
    let refList = this.refList.current?.instance;
    if (!refList) return;
    let filteredData = [];
    let _data = this.state.dataFiltered;
    if (value !== "CL")
      filteredData = _data.filter(
        (o) => this.getUserPrompt(o.CurrentResult) === value
      );
    else
      filteredData = _data.filter((o) => !o.EventSubtypeDesc.includes("eCIL"));
    setTimeout(() => {
      refList._dataSource._store._array = filteredData;
      refList.reload();
      displayPreload(false);
    }, 250);
  };

  scrollToTop = () => {
    let elem = document.getElementsByClassName("accslide");
    if (elem.length) elem[0].scrollTo(0, 0);
  };

  onClickFieldSelector = () => {
    this.setState({ showMainFields: true });
  };

  onSelectedFieldsChange = (args) => {
    if (args.name === "selectedItems") {
      this.setState({
        selectedFields: args.value,
      });
    }
  };

  onClickCustomize = () => {
    this.setState({ showCustomViewDialog: true });
  };

  filterColumns = (columns) => {
    return columns?.filter(
      (x) =>
        x.dataField !== "IsSelected" &&
        x.dataField !== "IsEdited" &&
        x.dataField !== "ColDoc" &&
        x.dataField !== "ColInfo" &&
        x.dataField !== "VarDesc" &&
        x.dataField !== "CurrentResult" &&
        x.dataField !== "NbrDefects" &&
        x.dataField !== "ItemNo" &&
        // x.dataField !== "TaskOrder" &&
        x.dataField !== "ColMove"
    );
  };

  applyCustomView = (view) => {
    let columns = view.columns;
    let localFields = [];
    let visibleFields = [];
    let newFields = [];
    let fieldsOrders = [];

    [...gridColumns(this.props.t)].forEach((x, index) => {
      localFields.push({
        dataField: x.dataField,
        caption: x.caption,
        visibility: false,
        order: index,
      });
    });

    localFields = this.filterColumns(localFields);
    columns = this.filterColumns(columns);

    columns.forEach((x) => {
      if (x.visible) {
        let temp = localFields.find(
          (f) => f.dataField === x.dataField
        )?.caption;
        if (temp !== undefined) visibleFields.push(temp);
      }
    });
    visibleFields = visibleFields.map(
      (x) => (x = localFields.find((y) => y.caption === x).caption)
    );

    localFields.forEach((x, i) => {
      let length = newFields.length;
      let temp = columns.find((y) => y.dataField === x.dataField);
      if (temp !== undefined) {
        if (temp.visible) {
          x.order = temp.visibleIndex;
          x.visibility = true;
          newFields.push(x);
        } else {
          x.order = length + 1;
          x.visibility = false;
          newFields.push(x);
        }
      } else {
        x.order = length + 1;
        x.visibility = false;
        newFields.push(x);
      }
    });
    newFields.sort((a, b) =>
      a.order > b.order ? 1 : b.order > a.order ? -1 : 0
    );

    fieldsOrders = newFields.map((x) => x.caption);

    newFields = this.moveSpecificationsToEnd(newFields);

    this.setState(
      {
        selectedFields: visibleFields,
        fieldsCaption: fieldsOrders,
        fields: newFields,
        selectedCustomView: view,
      },
      () => {
        this.buildColumns(true, 3);
      }
    );
  };

  fieldsData = () => {
    let fields = [];
    let selectedFields = this.state.selectedFields;
    let localFields = this.state.fields;
    localFields.forEach((x, i) => {
      let temp = selectedFields.find((o) => o === x.caption);
      if (temp !== undefined) fields.push(temp);
    });
    fields = fields.map(
      (x) => (x = localFields.find((y) => y.caption === x).dataField)
    );
    return fields;
  };

  calculateHeight = () => {
    let selector = document.querySelector("#crdTasksSelectionGrid");

    if (selector !== null) {
      let size = selector.offsetHeight - 25;
      return size.toString().concat("px");
    }

    return "100%";
  };

  onDragEnd = (e) => {
    let fields = this.state.fields;
    let newOrderItems = e.fromData;

    setTimeout(() => {
      newOrderItems.forEach((item, index) => {
        fields.find((x) => x.caption === item).order = index;
      });
      fields.sort((a, b) =>
        a.order > b.order ? 1 : b.order > a.order ? -1 : 0
      );
      this.setState({ fields });
    }, 1000);
  };

  columnChooserItemRender = (item) => {
    const { t } = this.props;
    let { value, type } = this.state.sortBy;
    return (
      <div className={styles.columnChooserItem}>
        <div className={styles.title}>{t(item)}</div>
        <div className={styles.columnChooserButtons}>
          <Button
            text={t("↑")}
            classes={styles.button}
            style={
              item === value &&
              type === "asc" && {
                backgroundColor: "#6a97c7d9",
                color: "#FFF",
              }
            }
            onClick={(e) => {
              this.setState({ sortBy: { value: item, type: "asc" } });
            }}
          />
          <Button
            text={t("↓")}
            classes={styles.button}
            style={
              item === value &&
              type === "desc" && {
                backgroundColor: "#6a97c7d9",
                color: "#FFF",
              }
            }
            onClick={(e) => {
              this.setState({ sortBy: { value: item, type: "desc" } });
            }}
          />
        </div>
      </div>
    );
  };

  sortTasks = (field = "") => {
    let refList = this.refList?.current?.instance;
    if (!refList) return;
    let data = refList._dataSource._store._array;
    if (!data?.length) return;
    let { sortBy, fields } = this.state;
    let { value, type } = sortBy;
    fields.forEach((x) => {
      if (x.caption === value) field = x.dataField;
    });
    if (type === "asc")
      data.sort(function (a, b) {
        return a[field] > b[field] ? 1 : -1;
      });
    else
      data.sort(function (a, b) {
        return a[field] < b[field] ? 1 : -1;
      });
    this.refreshSelectedItems();
  };

  onClickTourMap = () => {
    this.setState({ showTourMapLinks: true });
  };

  accordionHandler = (tourSelected, closing = false) => {
    let TourDesc = tourSelected?.TourDesc;
    let divs = document.getElementsByClassName("accslide");
    let tourMapId = document.getElementById("tourMapId");
    const expandedFull_leftPanel = "96%";
    const expandedWidth_leftPanel = "54%";
    const expandedWidth_rightPanel = "40%";
    let isExpanded = divs[0]?.style.width === expandedWidth_rightPanel;
    if (!divs || !divs[0]) return;
    if (closing) {
      tourMapId.style.display = "none";
      divs[0].style.width = expandedFull_leftPanel;
      divs[1].style.width = "0%";
      this.setState(
        {
          tourMapLink: "",
          dataFiltered: this.state.data,
          TourDesc,
          noTourStopTasksMessage: "",
          isExpanded: false,
          lastFilter: "",
          sortBy: {
            value: "Due Date",
            type: "asc",
          },
        },
        () => {
          if (Object.keys(this.state.selectedCustomView).length)
            this.applyCustomView(this.state.selectedCustomView);
          else this.setInitialColumns();
          this.refGridTourMaps.current?.instance.clearSelection();
          this.sortTasks();
          this.updateQuantitiesTasks();
        }
      );
      return;
    }
    if (tourSelected?.TourId) {
      displayPreload(true);
      getTourMapImage(tourSelected.TourId).then((imgdata) => {
        let tourMapLink = imgdata;
        let data = this.state.data;
        let res = [];
        let noTourStopTasksMessage = "";
        res = data.filter((x) => x.TourId === tourSelected.TourId);
        noTourStopTasksMessage = res.length
          ? ""
          : "No tasks for this tour stop";
        if (!imgdata || imgdata?.status === 500) {
          // no image
          this.setState(
            {
              dataFiltered: res,
              showTourMapLinks: false,
              noTourStopTasksMessage,
              isExpanded: false,
            },
            () => {
              warning("There is no image uploaded for this Tour Stop");
              tourMapId.style.display = "none";
              divs[0].style.width = expandedFull_leftPanel;
              divs[1].style.width = "0%";
              this.accordionHandler(null, true);
              displayPreload(false);
            }
          );
          return;
        } else if (isExpanded) {
          this.setState(
            {
              tourMapLink,
              dataFiltered: res,
              showTourMapLinks: false,
              TourDesc,
              noTourStopTasksMessage,
              lastFilter: "",
              sortBy: {
                value: "Tour Stop Task Order",
                type: "asc",
              },
            },
            () => {
              setTimeout(() => {
                tourMapId.style.display = "block";
                this.sortTasks();
                this.updateQuantitiesTasks();
                displayPreload(false);
              }, 500);
            }
          );
          return;
        } else if (!isExpanded) {
          divs[0].style.width = expandedWidth_rightPanel;
          divs[1].style.width = expandedWidth_leftPanel;
          let torMapColumns = [
            "Info",
            "Tour Stop Task Order",
            "Task Description",
            "Doc",
            "Due Date",
            "Value",
            "Comment",
            "Defects",
          ];
          this.setState(
            {
              tourMapLink,
              showTourMapLinks: false,
              dataFiltered: res,
              TourDesc,
              noTourStopTasksMessage,
              isExpanded: true,
              selectedFields: torMapColumns,
              lastFilter: "",
              sortBy: {
                value: "Tour Stop Task Order",
                type: "asc",
              },
            },
            () => {
              this.buildColumns(true);
              setTimeout(() => {
                tourMapId.style.display = "block";
                this.sortTasks();
                this.updateQuantitiesTasks();
                displayPreload(false);
              }, 1500);
            }
          );
        }
      });
    }
  };

  render() {
    const { t, viewActive } = this.props;
    let disabledAccess = getProfile().GlobalAccessLevel === 1;
    let {
      data,
      originalData,
      fieldsCaption,
      showMainFields,
      selectedFields,
      lastFilter,
      pendingSum,
      lateSum,
      defectSum,
      okSum,
      CLSum,
      showPostponeTaskDialog,
      showCustomViewDialog,
      chooserOption,
      showTourMapLinks,
      tourMapLink,
      TourDesc,
      noTourStopTasksMessage,
      dataFiltered,
      taskInfoDS,
      showInformationTable,
      isExpanded,
      tourMaps,
      disableCompleteAll,
      showHSE,
      showPQF,
      showQType,
      showImagePopup,
    } = this.state;
    let noTaskMessage = viewActive.toLowerCase().includes("route")
      ? t("No tasks are currently due for this route.")
      : t("No tasks are currently due for this selection.");

    let borderStyleSelectedFilter = "2px solid #012769";

    return (
      <>
        <Popup
          visible={showHSE}
          onHiding={() => this.setState({ showHSE: false })}
          maxWidth="450px"
          maxHeight="600px"
          title={t("HSE (Health, Safety, Environmental)")}
        >
          <div style={{ textAlign: "center" }}>
            <p>
              HSE type tasks have an influence on Health, Safety & Environment
              and, if not properly done, may result in an injury, environmental
              damage, or other Safety Incident.
            </p>
          </div>
          <br />
          <div style={{ textAlign: "center" }}>
            <Button
              text={t("Ok")}
              style={{ width: "80px" }}
              onClick={() => {
                this.setState({ showHSE: false });
              }}
            />
          </div>
        </Popup>
        <Popup
          visible={showPQF}
          onHiding={() => this.setState({ showPQF: false })}
          maxWidth="450px"
          maxHeight="600px"
          title={t("PQF (Primary Q-Factor) ")}
        >
          <div style={{ textAlign: "center" }}>
            <p>
              PQF type tasks or parameters have a proven direct impact on the
              quality of the product and, if not properly maintained or is out
              of compliance, WILL result in off-quality product or Quality
              Incident.
            </p>
          </div>
          <br />
          <div style={{ textAlign: "center" }}>
            <Button
              text={t("Ok")}
              style={{ width: "80px" }}
              onClick={() => {
                this.setState({ showPQF: false });
              }}
            />
          </div>
        </Popup>
        <Popup
          visible={showQType}
          onHiding={() => this.setState({ showQType: false })}
          maxWidth="450px"
          maxHeight="600px"
          title={t("QF (Quality Factor) ")}
        >
          <div style={{ textAlign: "center" }}>
            <p>
              QF type tasks or parameters, if not completed or is out of
              compliance, might result in off-quality product or a Quality
              Incident.
            </p>
          </div>
          <br />
          <div style={{ textAlign: "center" }}>
            <Button
              text={t("Ok")}
              style={{ width: "80px" }}
              onClick={() => {
                this.setState({ showQType: false });
              }}
            />
          </div>
        </Popup>
        <Popup
          id="showCustomViewDialog"
          visible={showCustomViewDialog}
          onHiding={() => {
            this.setState({ showCustomViewDialog: false });
          }}
          width="750px"
        >
          <CustomViewDialog
            t={t}
            viewName="iPadDataEntry"
            selectedTailsFields={this.fieldsData}
            applyCustomView={(view) => this.applyCustomView(view)}
            opened={showCustomViewDialog}
          />
        </Popup>
        {showImagePopup && (
          <ViewImagePopup
            t={this.props.t}
            showImage={true}
            tourMapLink={tourMapLink}
            TourDesc={TourDesc}
            closeImagePopup={() => {
              this.setState({
                showImagePopup: false,
              });
            }}
          />
        )}
        {!originalData?.length && (
          <div className={styles.isDefectLookedMessage}>
            <Icon name="circle-info" />
            <label>{noTaskMessage}</label>
          </div>
        )}

        <div className={styles.contentTails}>
          <div className={styles.headerFiltersContainer}>
            <div className={styles.headerFilters}>
              <div className={styles.filterButtons}>
                <form style={{ border: "1px solid #ccc", padding: "5px" }}>
                  <Button
                    id="btnPending"
                    text={t("Pending")}
                    onClick={() => this.onClickFilterButton("Pending")}
                    style={{
                      border: lastFilter.includes("Pending")
                        ? borderStyleSelectedFilter
                        : "",
                    }}
                  />
                  {pendingSum !== 0 && (
                    <div className={styles.sumTasksContainer}>
                      <span>{pendingSum}</span>
                    </div>
                  )}
                  <Button
                    id="btnLate"
                    text={t("Late")}
                    onClick={() => this.onClickFilterButton("Late")}
                    style={{
                      border: lastFilter.includes("Late")
                        ? borderStyleSelectedFilter
                        : "",
                    }}
                  />
                  {lateSum !== 0 && (
                    <div className={styles.sumTasksContainer}>
                      <span>{lateSum}</span>
                    </div>
                  )}
                  <Button
                    id="btnOpenDefects"
                    text={t("Open Defects")}
                    onClick={() => this.onClickFilterButton("Defect")}
                    style={{
                      border: lastFilter.includes("Defect")
                        ? borderStyleSelectedFilter
                        : "",
                    }}
                  />
                  {defectSum !== 0 && (
                    <div className={styles.sumTasksContainer}>
                      <span>{defectSum}</span>
                    </div>
                  )}
                  {/* "Ok" filter */}
                  {okSum !== 0 && (
                    <>
                      <Button
                        id="btnOk"
                        text={t("Ok")}
                        onClick={() => this.onClickFilterButton("Ok")}
                        style={{
                          border: lastFilter.includes("Ok")
                            ? borderStyleSelectedFilter
                            : "",
                        }}
                      />
                      <div className={styles.sumTasksContainer}>
                        <span>{okSum}</span>
                      </div>
                    </>
                  )}
                  {CLSum !== 0 && (
                    <>
                      <Button
                        id="btnCL"
                        text={t("Centerline")}
                        onClick={() => this.onClickFilterButton("CL")}
                        style={{
                          border: lastFilter.includes("CL")
                            ? borderStyleSelectedFilter
                            : "",
                        }}
                      />
                      <div className={styles.sumTasksContainer}>
                        <span>{CLSum}</span>
                      </div>
                    </>
                  )}
                </form>
              </div>

              <div className={styles.filterButtonsLeft}>
                <Button
                  id="btnFiltersiPad"
                  hint={"Show/Hide Filters"}
                  classes={styles.btnCardsFiltersRight}
                  icon={"filter"}
                  onClick={this.props.handlerFilters}
                />
                {viewActive.toLowerCase().includes("routes") && (
                  <Button
                    id="btnTourMapLink"
                    hint={"Tour Map Link"}
                    classes={styles.btnCardsFiltersRight}
                    imgsrc={icons.map}
                    onClick={() => this.onClickTourMap()}
                  />
                )}
                {!disabledAccess && (
                  <Button
                    id="btnCompleteAllTasksSelection"
                    hint={t("Complete All")}
                    classes={styles.btnCardsFiltersLeft}
                    icon="list-check"
                    onClick={() => this.onCompleteAllTasks()}
                    disabled={disableCompleteAll}
                  />
                )}

                <Button
                  id="btnCustomizeTailsTasksSelection"
                  hint={t("Customize")}
                  classes={styles.btnCardsFiltersLeft}
                  icon="chalkboard-user"
                  onClick={() => this.onClickCustomize()}
                  disabled={isExpanded}
                />

                <Button
                  id="btnRefreshTailsTasksSelection"
                  hint={t("Refresh")}
                  classes={styles.btnCardsFiltersLeft}
                  icon="rotate-right"
                  onClick={() => this.onClickRefreshTails()}
                />

                <Button
                  id="btnFieldsSeletor"
                  hint={t("Fields Seletor")}
                  classes={styles.btnCardsFiltersLeft}
                  icon="columns"
                  onClick={() => this.onClickFieldSelector()}
                />
              </div>
            </div>
          </div>

          <div>
            <ul
              id="tabs"
              style={{ width: "100%", transform: "translate(-30px, 10px)" }}
              class="accordion"
              className={nav.accordion}
            >
              <li>
                <input
                  id="rad1"
                  type="checkbox"
                  name="rad"
                  checked={true}
                  class="accInput"
                  onClick={() => this.accordionHandler("", true)}
                />
                <div
                  class="accslide"
                  style={{ width: "94%", overflowX: "none" }}
                >
                  <div class="contentiPad">
                    {noTourStopTasksMessage !== "" ? (
                      <div>
                        <div
                          className={styles.eDhNotAccessMessage}
                          style={{ float: "none" }}
                        >
                          <Icon name="circle-info" />
                          <label>{noTourStopTasksMessage}</label>
                        </div>
                        <br />
                      </div>
                    ) : (
                      <>
                        <div>
                          <List
                            id="lstTasksSelection"
                            ref={this.refList}
                            dataSource={dataFiltered}
                            nextButtonText={t("Load more tasks")}
                            searchEnabled={true}
                            searchExpr="VarDesc"
                            searchMode={"contains"}
                            height="100%"
                            selectionMode="multiple"
                            itemRender={this.taskItemRender}
                            onItemClick={(item) => this.onItemCardClick(item)}
                            showScrollbar="always"
                            activeStateEnabled={false}
                            scrollByContent={true}
                            repaintChangesOnly={false}
                            refreshingText="Refreshing..."
                            pageLoadMode="nextButton"
                          />
                        </div>
                        <div className={styles.bottomCommands}>
                          <Button
                            id="btnScrollToTop"
                            title={t("Back to top")}
                            icon="chevron-up"
                            primary
                            classes={styles.scrollToTop}
                            onClick={() => {
                              this.scrollToTop();
                            }}
                          />
                        </div>
                        <div className={styles.fixedSaveButton}>
                          <Button
                            id="btnSaveDeviceTasks"
                            icon="save"
                            text={t("Save")}
                            primary
                            style={{ width: "100px" }}
                            onClick={this.onSaveSelectedTasks}
                          />
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </li>
              <li>
                <div class="accslide">
                  <div
                    id="tourMapId"
                    class="contentiPad"
                    style={{ display: "none" }}
                  >
                    <Button
                      classes={styles.buttons}
                      icon="up-right-and-down-left-from-center"
                      style={{
                        float: "right",
                        cursor: "pointer",
                        marginTop: "-5px",
                      }}
                      onClick={() => this.setState({ showImagePopup: true })}
                    />

                    <Button
                      classes={styles.buttons}
                      imgsrc={icons.close}
                      style={{
                        float: "right",
                        cursor: "pointer",
                        marginTop: "-5px",
                      }}
                      onClick={() => this.accordionHandler("", true)}
                    />
                    <label
                      style={{ fontSize: "small", whiteSpace: "pre-wrap" }}
                    >
                      <strong>{t("Tour Stop")}:</strong>
                      {TourDesc}
                    </label>
                    <div style={{ padding: "20px 0px" }}>
                      <TransformWrapper initialScale={1}>
                        {({ zoomIn, zoomOut, resetTransform, ...rest }) => (
                          <React.Fragment>
                            <TransformComponent>
                              <img
                                src={`data:image/jpeg;base64,${tourMapLink}`}
                                alt=""
                                width={"100%"}
                              />
                            </TransformComponent>
                          </React.Fragment>
                        )}
                      </TransformWrapper>
                    </div>
                  </div>
                </div>
              </li>
            </ul>
          </div>

          <br />

          <Popup
            id="showPostponeTaskDialog"
            reference={this.refPostponeDialog}
            title={t("Postponed Task")}
            visible={showPostponeTaskDialog}
            onHiding={() => {
              this.setState({ showPostponeTaskDialog: false });
            }}
            width="300px"
          >
            <form className={styles.moveDialog}>
              <div>
                <h5>
                  {t("Current Schedule Time")}
                  <label name="txtCurrentTime"></label>
                </h5>
                <hr />
                <h5>{t("Postponed Schedule Time")}:</h5>
                <DateBox
                  type="datetime"
                  ref={this.refDtpPostponedTask}
                  displayFormat="yyyy-MM-dd HH:mm"
                  pickerType="native"
                  acceptCustomValue={false}
                />
                <hr />
              </div>

              <Button
                text={t("Accept")}
                onClick={() => this.onAceptPostpone()}
              />
            </form>
          </Popup>

          <Popup
            id="showMainFields"
            visible={showMainFields}
            width="300px"
            // height="50%"
            dragEnabled={true}
            onHiding={() => {
              this.setState({ showMainFields: false });
            }}
          >
            <div style={{ marginBottom: "15px" }}>
              <Button
                text={t("Fields chooser")}
                primary={chooserOption}
                style={{ width: "120px" }}
                onClick={() => this.setState({ chooserOption: true })}
              />
              <Button
                text={t("tasks sort")}
                primary={!chooserOption}
                style={{ width: "120px" }}
                onClick={() => this.setState({ chooserOption: false })}
              />
            </div>
            {chooserOption ? (
              <List
                id="lstFieldsSelector"
                ref={this.refFieldsList}
                items={fieldsCaption}
                showSelectionControls={true}
                height="100%"
                className={styles.fields}
                selectionMode="all"
                selectedItems={selectedFields}
                onOptionChanged={this.onSelectedFieldsChange}
              >
                <ItemDragging
                  allowReordering={true}
                  data={fieldsCaption}
                  onDragEnd={this.onDragEnd}
                ></ItemDragging>
              </List>
            ) : (
              <List
                id="lstFieldsSort"
                items={selectedFields}
                showSelectionControls={true}
                selectionMode="single"
                style={{ display: "flex", minHeight: "400px" }}
                className={styles.fields}
                itemRender={this.columnChooserItemRender}
              ></List>
            )}

            <br />
            <div style={{ textAlign: "center" }}>
              <Button
                text={t("Ok")}
                primary
                style={{ width: "60px" }}
                onClick={() => {
                  !chooserOption
                    ? this.setState({ chooserOption: true }, () =>
                        this.buildColumns(true, isExpanded ? 1 : 3)
                      )
                    : this.buildColumns(true, isExpanded ? 1 : 3);
                  this.sortTasks();
                }}
              />
            </div>
          </Popup>
          <Popup
            id="showTourMapLinks"
            visible={showTourMapLinks}
            onHiding={() => this.setState({ showTourMapLinks: false })}
            width="400px"
            height="400px"
            title={t("Tour Stops Maps")}
            dragEnabled={true}
          >
            <div>
              {tourMaps?.length ? (
                <>
                  <DataGrid
                    identity="grdTourStop"
                    keyExpr="TourId"
                    reference={this.refGridTourMaps}
                    dataSource={tourMaps}
                    showBorders={false}
                    rowAlternationEnabled={false}
                    allowFiltering={false}
                    headerFilter={{ visible: false }}
                    filterRow={false}
                    height="280px"
                  >
                    <Column
                      dataField={"TourDesc"}
                      caption={t("Tour Stop")}
                      allowSearch={false}
                      allowSorting={false}
                    />
                    <Selection mode="single" showCheckBoxesMode="none" />
                  </DataGrid>
                  <br />
                  <div style={{ textAlign: "center" }}>
                    <Button
                      text={t("Ok")}
                      primary
                      style={{ width: "60px" }}
                      onClick={() => {
                        let refGridTourMaps =
                          this.refGridTourMaps.current?.instance.getSelectedRowsData();
                        refGridTourMaps?.length
                          ? this.accordionHandler(refGridTourMaps[0], false)
                          : this.setState({ showTourMapLinks: false });
                      }}
                    />
                    <Button
                      text={t("Cancel")}
                      style={{ width: "80px" }}
                      onClick={() => {
                        this.setState({ showTourMapLinks: false });
                      }}
                    />
                    <Button
                      text={t("Close Right Panel")}
                      style={{ width: "200px" }}
                      disabled={
                        document.getElementsByClassName("accslide")[0]?.style
                          .width !== "40%"
                      }
                      onClick={() => {
                        this.accordionHandler("", true);
                        this.setState({
                          dataFiltered: data,
                          showTourMapLinks: false,
                        });
                      }}
                    />
                  </div>
                </>
              ) : (
                <div
                  className={styles.isDefectLookedMessage}
                  style={{ height: "35px" }}
                >
                  {/* <img alt="" src={icons.info} /> */}
                  <Icon name="circle-info" />

                  <label>
                    {t("No tour stops are assigned for this selection.")}
                  </label>
                </div>
              )}
            </div>
          </Popup>
          <Popup
            id="showInformationTable"
            visible={showInformationTable}
            onHiding={() => this.setState({ showInformationTable: false })}
            maxWidth="450px"
            maxHeight="600px"
            title={t("Task Infomation")}
          >
            <DataGrid
              identity="grdTourStop"
              reference={this.refInfoGrid}
              dataSource={taskInfoDS}
              showBorders={false}
              rowAlternationEnabled={true}
              allowFiltering={false}
              headerFilter={{ visible: false }}
              filterRow={false}
              height="400px"
              wordWrapEnabled={true}
              onToolbarPreparing={(e) => {
                let grid = this.refInfoGrid.current?.instance;
                return e.toolbarOptions.items.unshift({
                  location: "after",
                  widget: "dxButton",
                  cssClass: "btnExcelExportTasksSelection",
                  options: {
                    hint: t("Export to Excel"),
                    icon: getIcon("file-excel"),
                    onClick: () => grid.exportToExcel(false),
                  },
                });
              }}
            >
              <Column
                dataField={"caption"}
                caption={t("Item")}
                allowSearch={false}
                allowSorting={false}
              />
              <Column
                dataField={"value"}
                caption={t("Description")}
                allowSearch={false}
                allowSorting={false}
              />
            </DataGrid>

            <br />
            <div style={{ textAlign: "center" }}>
              <Button
                text={t("Ok")}
                style={{ width: "80px" }}
                onClick={() => {
                  this.setState({ showInformationTable: false });
                }}
              />
            </div>
          </Popup>
        </div>
      </>
    );
  }
}

export default ListItems;
