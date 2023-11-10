import React, { PureComponent } from "react";
// import QRCode from "qrcode.react";
import Card from "../../../components/Card";
import DataGrid from "../../../components/DataGrid";
import Button from "../../../components/Button";
import RadioGroup from "../../../components/RadioGroup";
import SelectBox from "../../../components/SelectBox";
import { setBreadcrumbEvents } from "../../../components/Framework/Breadcrumb/events";
import { entriesCompare, isTablet } from "../../../utils";
import { getLines, getUnits, getWorkcells } from "../../../services/plantModel";
import { getAllRoutes } from "../../../services/routes";
import {
  getLineTasksSelection,
  getRoutesTasksSelection,
} from "../../../services/tasks";
import { updatePlantModelView, filterGrid } from "../TasksSelection/options";
import { Selection } from "devextreme-react/ui/data-grid";
import { displayPreload } from "../../../components/Framework/Preload";
import { getAllQRFortask } from "../../../services/qrcodes";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import QrCodeGrid from "./subs/datagrid";
import ViewQr from "./subs/viewQr";
import SaveQr from "./subs/saveQr";
import dayjs from "dayjs";
import icons from "../../../resources/icons";
import styles from "./styles.module.scss";
import { alert } from "devextreme/ui/dialog";

class ByTask extends PureComponent {
  constructor(props) {
    super(props);

    this.refGrid = React.createRef();
    this.refFormNewQr = React.createRef();
    this.refAccordion = React.createRef();

    this.state = {
      lines: [],
      units: [],
      workcells: [],
      routes: [],
      group: "byLine",
      selected: {
        lines: [],
        units: [],
        workcells: [],
        myroutes: [],
      },
      tasks: [],
      qrDataSource: [],
      qrcode: false,
      qrvalue: "",
      containersHeight: 0,
      showsaveQr: false,
      dataEdit: {},
      selectedVarIds: [],
      isEditing: false,
      messageDisplayed: false,
    };
  }

  componentDidMount = () => {
    displayPreload(true);
    getLines().then((response) =>
      this.setState(
        {
          lines: response,
        },
        () => {
          this.getAllRoutes();
          this.setItemHeight();
          this.refAccordion.current.instance.collapseItem(0);
          setTimeout(() => {
            let item = document.getElementsByClassName(
              "dx-accordion-item-closed"
            )[0];
            item.style.border = "1px solid #003da5";
            displayPreload(false);
          }, 500);
        }
      )
    );
    this.setBreadcrumb();
  };

  getAllRoutes = () => {
    getAllRoutes().then((response) => {
      this.handlerData(response);
    });
  };

  reloadRoutesAffterDeleteQr = (newRoute) => {
    let routes = this.state.routes;
    routes.unshift(newRoute);
    this.setState({
      routes,
    });
  };

  setBreadcrumb = () => {
    const { t } = this.props;
    setBreadcrumbEvents(
      <nav>
        <Button
          id="btnQrCode"
          icon="qrcode"
          hint={t("Generate/Update QR Code")}
          primary
          disabled={false}
          classes={styles.breadcrumbButton}
          onClick={this.onClickGenerateQR}
        />
      </nav>
    );
    this.enableQRButton(false);
  };

  handlerData = (routes = [], showQrView = false, qrSaved = {}) => {
    let newRoutes = routes.length ? routes : [...this.state.routes];
    getAllQRFortask().then((response) => {
      // If a RouteID is already stored in the DB, do not show it in DropDown
      response?.forEach((route) => {
        route.QrDate = dayjs(route.QrDate).format("YYYY-MM-DD HH:mm");
        let temp = newRoutes.find((x) => x.RouteId === route.RouteId);
        if (temp) {
          let index = newRoutes.indexOf(temp);
          newRoutes.splice(index, 1);
        }
      });

      qrSaved.QrId =
        response.find((qr) => qr.QrName === qrSaved?.QrName || "")?.QrId ||
        null;

      this.setState(
        {
          dataEdit: qrSaved,
          qrDataSource: response,
          routes: newRoutes,
          qrcode: showQrView,
        },
        () => this.enableQRButton(false)
      );
    });
  };

  componentDidUpdate = (prevProps, prevState) => {
    this.handlerFilters(prevState);
  };

  handlerFilters = (prevState) => {
    let { group, dataEdit, isEditing } = this.state;
    let { group: prevGroup } = prevState;
    let { lines, workcells, units, myroutes } = this.state.selected;
    let {
      lines: prevLines,
      units: prevUnits,
      workcells: prevWorkcells,
      myroutes: prevMyRoutes,
    } = prevState.selected;
    let selectedVarIds = [];

    if (!lines?.length && prevLines?.length) this.setState({ tasks: [] });
    if (!myroutes?.length && prevMyRoutes?.length) this.setState({ tasks: [] });

    if (group !== prevGroup && !isEditing) return;

    if (group === "byRoute") {
      if (
        (myroutes !== prevMyRoutes && prevMyRoutes && myroutes.length) ||
        isEditing
      ) {
        displayPreload(true);
        let ds = dataEdit?.VarId || "";
        if (ds)
          ds.split(",").forEach((item) => selectedVarIds.push(parseInt(item)));
        getRoutesTasksSelection(myroutes.join(",")).then((response) => {
          this.setState(
            {
              tasks: response || [],
              selectedVarIds,
              isEditing: false,
            },
            () =>
              setTimeout(() => {
                displayPreload(false);
              }, 500)
          );
        });
      }
    }

    if (group === "byLine") {
      if (
        (lines !== prevLines && prevLines && lines.length) ||
        (isEditing && Object.keys(dataEdit).length !== 0)
      ) {
        displayPreload(true);
        getLineTasksSelection(lines).then((response) => {
          let ds = dataEdit?.VarId || "";
          ds.split(",").forEach((item) => selectedVarIds.push(parseInt(item)));
          this.setState(
            {
              tasks: response || [],
              selectedVarIds,
            },
            () =>
              setTimeout(() => {
                displayPreload(false);
              }, 500)
          );
        });
      }

      if (prevLines !== lines && lines.length > 0) {
        getUnits(lines.join(",")).then((response) => {
          if (lines.length > 0) {
            let unitsStored = units;
            if (Object.keys(dataEdit).length !== 0) {
              unitsStored = dataEdit.Unit?.split(",");
              unitsStored = unitsStored?.map((x) => parseInt(x)) || [];
            }
            this.setState({
              units: response,
              selected: {
                ...this.state.selected,
                units: lines !== prevLines && !isEditing ? [] : unitsStored,
              },
            });
          }
        });
      }

      if (prevUnits !== units && units?.length > 0) {
        getWorkcells(units.join(",")).then((response) => {
          if (units.length > 0) {
            let workcellsStored = workcells;
            if (Object.keys(dataEdit).length !== 0) {
              workcellsStored = dataEdit.Workcell?.split(",");
              workcellsStored = workcellsStored?.map((x) => parseInt(x)) || [];
            }
            this.setState({
              workcells: response,
              selected: {
                ...this.state.selected,
                workcells: workcellsStored,
              },
              isEditing: false,
            });
          }
        });
      }
    }

    if (prevUnits !== units || prevWorkcells !== workcells) {
      this.setFiltersGrid();
    }
  };

  onClickDetailEdit = (selected) => {
    if (selected.Line) {
      let linesStored = selected.Line?.split(",");
      linesStored = linesStored.map((x) => parseInt(x)) || [];
      this.setState(
        {
          group: "byLine",
          dataEdit: selected,
          isEditing: true,
          tasks: [],
          selectedVarIds: [],
          selected: {
            lines: linesStored,
            units: [],
            workcells: [],
            myroutes: [],
          },
        },
        () => this.refAccordion.current.instance.expandItem(0)
      );
    } else if (selected.RouteIdstr) {
      let routesStored = selected.RouteIdstr?.split(",");
      routesStored = routesStored.map((x) => parseInt(x)) || [];
      this.setState(
        {
          group: "byRoute",
          dataEdit: selected,
          isEditing: true,
          selected: {
            lines: [],
            units: [],
            workcells: [],
            myroutes: routesStored,
          },
        },
        () => this.refAccordion.current.instance.expandItem(0)
      );
    }
  };

  handleSelectBox = (key, values) => {
    if (
      !entriesCompare(values, this.state.selected[key]) &&
      key !== "myroutes"
    ) {
      this.setState(
        {
          ...this.state,
          ...updatePlantModelView(key, values, this.state),
          selectedVarIds: [],
        },
        () => {
          if (!this.state.selected.lines.length) this.enableQRButton(false);
        }
      );
    } else {
      this.setState(
        {
          selected: {
            ...this.state.selected,
            myroutes: values,
            selectedVarIds: [],
          },
        },
        () => {
          if (!this.state.selected.myroutes.length) this.enableQRButton(false);
        }
      );
    }
  };

  enableQRButton = (val) => {
    setTimeout(() => {
      let btnQrCode = document.getElementById("btnQrCode");
      if (btnQrCode) {
        btnQrCode.disabled = !val;
      }
    }, 100);
  };

  setFiltersGrid = () => {
    this.handlerFilterGrid(filterGrid(this.state));
  };

  handlerFilterGrid = (filters) => {
    if (this.refGrid.current !== null)
      this.refGrid.current.instance.filter(filters);
  };

  onClickGenerateQR = (e) => {
    this.setState({ showsaveQr: true });
  };

  onClickCloseQrcodeView = () => {
    this.setState({ qrcode: false });
  };

  handleChange = (e) => {
    if (this.state.isEditing) return;
    this.setState(
      {
        group: e.value,
        selected: {
          lines: [],
          units: [],
          workcells: [],
          myroutes: [],
        },
        workcells: [],
        units: [],
        tasks: [],
        selectedVarIds: [],
        dataEdit: {},
        isEditing: false,
        messageDisplayed: false,
      },
      () => {
        this.enableQRButton(false);
      }
    );
  };

  onSelectionChanged = (e) => {
    let { selectedVarIds, messageDisplayed } = this.state;
    let refGrid = this.refGrid.current?.instance;
    let selectedRows = refGrid.getSelectedRowKeys() || [];
    let dataSource = refGrid.getDataSource()._store._array;
    let { currentSelectedRowKeys, selectedRowsData, currentDeselectedRowKeys } =
      e;
    if (!selectedRowsData.length) return;
    let messageAdding =
      "It looks like you have added one or more centerline task(s) associated with this route. To ensure accurate information, please re-print the QR code linked to this route.";
    let messageRemoving =
      "It looks like you have removed all centerline tasks associated with this route. To ensure accurate information, please re-print the QR code linked to this route.";
    let hadCLTasks = false;
    selectedVarIds.forEach((v) => {
      let EventSubtypeDesc = dataSource.find(
        (p) => p.VarId === v
      )?.EventSubtypeDesc;
      if (EventSubtypeDesc !== "eCIL" && EventSubtypeDesc) hadCLTasks = true;
    });

    /*  
    Case 1
       Show messageRemoving if the user is deselecting CL/s task/s and:
        1) Is the last CL tasks 
        2) There were saved CL tasks 
        3) In the saved tasks there was at least one CL task 
        4) The task being deselected is the last CL task
    */
    let conditionisRemoving = Boolean(
      currentDeselectedRowKeys.length === 1 &&
        hadCLTasks &&
        !this.hasCLTasks(selectedRowsData)
    );

    /*  
    Case 2
       Show message if the user is selectiong a CL tasks and:
        1) Is the first CL tasks.
        2) There were no saved CL tasks.
        3) In the saved tasks there was at least one CL task 
        4) The task being selected is the first CL task
    */
    let conditionAdding = Boolean(
      currentSelectedRowKeys.length === 1 &&
        !hadCLTasks &&
        this.hasCLTasks(selectedRowsData)
    );

    this.enableQRButton(selectedRows.length);

    if (
      (conditionisRemoving || conditionAdding) &&
      !messageDisplayed &&
      selectedVarIds.length
    ) {
      this.setState(
        {
          messageDisplayed: true,
        },
        () => {
          alert(conditionisRemoving ? messageRemoving : messageAdding);
          return;
        }
      );
    }
  };

  hasCLTasks = (tasks) => {
    if (!tasks) return;
    return tasks.some((x) => x?.EventSubtypeDesc !== "eCIL");
  };

  setItemHeight = () => {
    let containersHeight = document.getElementById("container").offsetHeight;
    this.setState({
      containersHeight: containersHeight - "100" + "px",
    });
  };

  onCloseSaveQr = () => {
    this.setState({ showsaveQr: false }, () => {
      this.refAccordion.current.instance.expandItem(1);
    });
  };

  removeRepitedVarIds = (array) => {
    return array.filter(
      (element, index, self) =>
        index === self.findIndex((t) => t.VarId === element.VarId)
    );
  };

  onClickCancelEdit = () => {
    this.handleChange({ value: this.state.group });
    this.refAccordion.current.instance.expandItem(1);
  };

  render() {
    const { t } = this.props;
    const {
      group,
      selected,
      qrDataSource,
      tasks,
      qrcode,
      lines,
      units,
      workcells,
      routes,
      containersHeight,
      showsaveQr,
      selectedVarIds,
      dataEdit,
    } = this.state;
    var noTask = Boolean(
      !tasks?.length &&
        (selected.lines?.length || selected.myroutes?.length || false)
    );

    return (
      <React.Fragment>
        <div className={styles.container}>
          <Card autoHeight id="container">
            <Accordion
              id="acdQrByTask"
              ref={this.refAccordion}
              collapsible={true}
              multiple={false}
              animationDuration={300}
              onSelectedItemChange={() => this.handleChange({ value: group })}
            >
              <Item title={t("Generate QR Code")}>
                <div style={{ height: containersHeight }}>
                  <div className={styles.rboQrCode}>
                    <div className={styles.headerLeft}>
                      <RadioGroup
                        items={[
                          { text: "By Line", value: "byLine" },
                          { text: "By Route", value: "byRoute" },
                        ]}
                        valueExpr="value"
                        displayExpr="text"
                        value={group}
                        onValueChanged={this.handleChange}
                      />
                    </div>
                    {Object.keys(dataEdit).length !== 0 && (
                      <div className={styles.headerRight}>
                        <Button
                          id="btnCancelEdit"
                          text={t("Cancel Edit")}
                          disabled={false}
                          imgsrc={icons.close}
                          primary
                          onClick={this.onClickCancelEdit}
                        />
                      </div>
                    )}
                  </div>

                  {group === "byLine" ? (
                    <div className={styles.multiSelectionGroup}>
                      <SelectBox
                        text={t("Production Line")}
                        id="sboLinesQRCode"
                        enableClear={true}
                        store={lines}
                        isMultiple={true}
                        className={styles.selectBox}
                        value={selected.lines}
                        onChange={(values) =>
                          this.handleSelectBox("lines", values)
                        }
                        labelKey="LineDesc"
                        valueKey="LineId"
                        isLoading={false}
                        isDisable={false}
                      />
                      <SelectBox
                        text={t("Primary Unit")}
                        id="sboUnitsQRCode"
                        enableClear={true}
                        store={units}
                        isMultiple={true}
                        className={styles.selectBox}
                        value={selected.units}
                        onChange={(values) =>
                          this.handleSelectBox("units", values)
                        }
                        labelKey="MasterDesc"
                        valueKey="MasterId"
                        isLoading={false}
                        isDisable={false}
                      />
                      <SelectBox
                        text={t("Module")}
                        id="sboWorkcellsQRCode"
                        enableClear={true}
                        store={workcells}
                        isMultiple={true}
                        className={styles.selectBox}
                        value={selected.workcells}
                        onChange={(values) =>
                          this.handleSelectBox("workcells", values)
                        }
                        labelKey="SlaveDesc"
                        valueKey="SlaveId"
                        isLoading={false}
                        isDisable={false}
                      />
                    </div>
                  ) : (
                    <div className={styles.multiSelectionGroup}>
                      <SelectBox
                        text={t("Routes")}
                        id="sboRoutes"
                        enableClear={true}
                        store={routes}
                        isMultiple={true}
                        className={styles.selectBox}
                        value={selected.myroutes}
                        onChange={(values) =>
                          this.handleSelectBox("myroutes", values)
                        }
                        labelKey="RouteDesc"
                        valueKey="RouteId"
                        isLoading={false}
                        isDisable={false}
                      />
                    </div>
                  )}

                  {tasks?.length ? (
                    <div className={styles.dgrConteiner}>
                      <DataGrid
                        identity="grdQRCode"
                        keyExpr="VarId"
                        reference={this.refGrid}
                        dataSource={this.removeRepitedVarIds(tasks)}
                        showBorders={false}
                        defaultSelectedRowKeys={selectedVarIds}
                        height="100%"
                        columns={[
                          {
                            dataField: "VarId",
                            allowFiltering: false,
                            visibility: false,
                          },
                          {
                            dataField: "VarDesc",
                            caption: t("Task Description"),
                            allowFiltering: true,
                          },
                        ]}
                        scrollingMode={isTablet() ? "virtual" : "standard"}
                        onSelectionChanged={this.onSelectionChanged}
                      >
                        <Selection
                          mode={"multiple"}
                          showCheckBoxesMode="always"
                          allowSelectAll={true}
                        />
                      </DataGrid>
                    </div>
                  ) : (
                    noTask && (
                      <div className={styles.noTaskContainer}>
                        <div className={styles.noTaskMessage}>
                          <img alt="" src={icons.info} />
                          <label>
                            {t("No tasks for the current selection.")}
                          </label>
                        </div>
                      </div>
                    )
                  )}
                </div>
              </Item>
              <Item title={t("QR Code Report")} className={styles.container}>
                <div style={{ height: containersHeight }}>
                  <QrCodeGrid
                    t={t}
                    by={"tasks"}
                    qrDataSource={qrDataSource}
                    handlerData={this.handlerData}
                    reloadRoutesAffterDeleteQr={this.reloadRoutesAffterDeleteQr}
                    onClickDetailEdit={this.onClickDetailEdit}
                  />
                </div>
              </Item>
            </Accordion>

            {qrcode && (
              <ViewQr
                t={t}
                by={group}
                selected={dataEdit}
                showHide={qrcode}
                onClickCloseQrcodeView={this.onClickCloseQrcodeView}
              />
            )}

            {showsaveQr && (
              <SaveQr
                t={t}
                by="task"
                handlerData={this.handlerData}
                dataEdit={dataEdit}
                selected={{
                  lines: selected?.lines || [],
                  workcells: selected?.workcells || [],
                  units: selected?.units || [],
                  myroutes: selected?.myroutes || [],
                  VarIds:
                    this.refGrid.current?.instance.getSelectedRowKeys() || [],
                }}
                onClickCloseSaveQrcode={this.onCloseSaveQr}
                qrDataSource={qrDataSource}
              />
            )}
          </Card>
        </div>
      </React.Fragment>
    );
  }
}

export default ByTask;
