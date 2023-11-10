import React, { PureComponent } from "react";
import {
  Column,
  Editing,
  Selection,
  Pager,
  Paging,
  RowDragging,
  Export,
  FilterRow,
  Sorting,
  Grouping,
  GroupPanel,
} from "devextreme-react/ui/data-grid";
import Form, {
  SimpleItem,
  Label,
  RequiredRule,
} from "devextreme-react/ui/form";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import { Selection as TreeListSelection } from "devextreme-react/ui/tree-list";
import { Template } from "devextreme-react/core/template";
import { alert, confirm } from "devextreme/ui/dialog";
import TreeList from "../../../../components/TreeList";
import DataGrid from "../../../../components/DataGrid";
import Button from "../../../../components/Button";
import Card from "../../../../components/Card";
import CheckBox from "../../../../components/CheckBox";
import { displayPreload } from "../../../../components/Framework/Preload";
import { getUserRole } from "../../../../services/auth";
import { warning, error } from "../../../../services/notification";
import {
  getRoutes,
  getRouteTeams,
  getReportRouteTasks,
  getRouteTasks,
  addRoute,
  updateRoute,
  deleteRoutes,
  updataRouteTeamsAssociations,
  updataRouteTasksAssociations,
  getReportAllRouteTeams,
  getReportAllRouteTasks,
  getReportRouteActivity,
  createRouteDisplay,
  updateDisplayVariablesAssociations,
  UpdateSheetDesc,
  IsIntegratedRoute,
  CheckIfRouteHasQR,
} from "../../../../services/routes";
import { getLines } from "../../../../services/plantModel";
import {
  generateExportDocument,
  getKeySorted,
  sortBy,
  getIcon,
} from "../../../../utils";
import {
  gridRoutesToolbarPreparing,
  gridRoutesColumns,
  gridTeamsToolbarPreparing,
  gridTeamsColumns,
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridAllRouteToolbarPreparing,
  gridAllRouteTeams,
  gridAllRouteTasks,
} from "./options";
import {
  buildTreeListLines,
  buildTreeListItems,
  treeListTasksSelected,
  treeListExpandedKeys,
} from "../shared";
import icons from "../../../../resources/icons";
import MyStepper from "./sub/stepper";
import styles from "./styles.module.scss";
import iconStyle from "../../../../components/Icon/styles.module.scss";
import {
  getTourStopInfo,
  getTourStop,
  AddTourStop,
  updatetourstoptasks,
  deleteTourStop,
  updateTourStopDesc,
  updateTourMapLink,
  getTourMapImageCount,
} from "../../../../services/tourStops";
import Save from "./sub/save-popup";

const tourStopsListColumns = [
  {
    dataField: "TourId",
    caption: "TourId",
    visibility: false,
    allowSearch: false,
  },
  {
    dataField: "TourMap",
    caption: "Tour Map",
    visibility: false,
    allowSearch: false,
  },
  {
    dataField: "TourOrder",
    caption: "Order",
    visibility: false,
    allowSearch: false,
    allowReordering: false,
  },
];

class RoutesManagement extends PureComponent {
  constructor(props) {
    super(props);

    this.refGridRoutes = React.createRef();
    this.refAccordion = React.createRef();
    this.refGridTeams = React.createRef();
    this.refGridTasks = React.createRef();
    this.refGridTourStops = React.createRef();
    this.refTreeList = React.createRef();
    this.refGridAllTeams = React.createRef();
    this.refGridAllTasks = React.createRef();
    this.refGridTourStopsListAdded = React.createRef();
    this.refTourMaps = React.createRef();

    this.toolbarItemRender = this.toolbarItemRender.bind(this);

    this.state = {
      tourStops: [],
      tourStopsList: [],
      routesDS: [],
      teamsDS: [],
      tasksDS: [],
      linesDS: [],
      routeSelected: {},
      routeDescSelected: "",
      displayRouteScreen: false,
      displayAllRouteTeams: false,
      displayAllRouteTasks: false,
      treeListData: [],
      selectedRowKeys: [],
      expandedRowKeys: [],
      scrollingMode: "",
      linesLoaded: [],
      tasksLoaded: [],
      containersHeight: "",
      step2AlreadyLoaded: false,
      step2_TasksWasUpdated: false,
      step2RouteDescUpdate: false,
      step3AlreadyLoaded: false,
      step4AlreadyLoaded: false,
      showSavePopup: false,
      stepWasUpdated: false,
      disableNextButton: true,
      isSelectingTourStop: false,
      step2_WasUpdated: false,
      step3_WasUpdated: false,
      step3Tasks_WasUpdated: false,
      step4_WasUpdated: false,
      tourStopTasks: [],
      columnsTaskGrid_Step3: [],
      showActivityValue: false,
      activityWasUpdated: false,
      isCheckedAll: false,
      taskIdsTourStop: [],
      isIntegratedRouteState: false,
      CheckIfRouteHasQRState: false,
    };
  }

  componentDidMount() {
    this.reloadRoutes();
    this.lines();
  }

  reloadRoutes = () => {
    displayPreload(true);

    let columnsTaskGrid_Step3 = gridTasksColumns(this.props.t);
    columnsTaskGrid_Step3.forEach((col) => {
      if (col.dataField === "TourTaskOrder") col.visibility = true;
      if (col.dataField === "TaskOrder") col.visibility = false;
    });

    getRoutes().then((response) => {
      this.setState(
        {
          routesDS: response,
          linesLoaded: [],
          selectedRowKeys: [],
          expandedRowKeys: [],
          scrollingMode: window.innerWidth > 992 ? "standard" : "virtual",
          columnsTaskGrid_Step3,
        },
        () => {
          displayPreload(false);
          if (this.state.displayRouteScreen) {
            this.refGridRoutes.current?.instance.refresh();
          }
        }
      );
    });
  };

  teams = (routId) => {
    return new Promise((resolve) =>
      resolve(
        getRouteTeams(routId).then((response) => {
          this.setState({
            teamsDS: response,
          });
          return response;
        })
      )
    );
  };

  tasks = (routId) => {
    return new Promise((resolve) =>
      resolve(
        getReportRouteTasks(routId).then((response) => {
          this.setState({
            tasksDS: response,
            linesLoaded: [],
            tasksLoaded: [...response],
            step2AlreadyLoaded: true,
          });
        })
      )
    );
  };

  lines = () => {
    let isRouteManagement = 1;
    return new Promise((resolve) =>
      resolve(
        getLines(null, isRouteManagement).then((response) => {
          this.setState({
            linesDS: response,
          });
        })
      )
    );
  };

  treeListData = (routeId) => {
    displayPreload(true);
    return new Promise((resolve) =>
      resolve(
        getRouteTasks(routeId).then((response) => {
          if (response?.length) {
            let selectedRowsIds = response
              .filter((f) => f.Selected)
              .map((m) => m.Id);
            let expandedRowKeys = treeListExpandedKeys(
              response,
              selectedRowsIds
            );

            let tempLinesLoaded = this.state.linesLoaded;
            let linesSelected = response.filter((x) => x.Level === 1);
            linesSelected.map((line) => {
              return tempLinesLoaded.push(line.ItemDesc);
            });
            this.setState(
              {
                treeListData: response,
                selectedRowKeys: selectedRowsIds,
                expandedRowKeys:
                  expandedRowKeys === undefined
                    ? response.map((m) => m.Id)
                    : expandedRowKeys,
                linesLoaded: tempLinesLoaded,
              },
              () => {
                buildTreeListLines(this.state).then((resp) => {
                  this.setState(
                    {
                      treeListData: resp,
                    },
                    () => {
                      this.refTreeList.current?.instance.refresh();
                      displayPreload(false);
                    }
                  );
                });
              }
            );
          } else {
            buildTreeListLines(this.state).then((resp) => {
              this.setState(
                {
                  treeListData: resp,
                },
                () => {
                  this.refTreeList?.current?.instance.refresh();
                  this.refAccordion?.current?.instance.expandItem(1);
                  displayPreload(false);
                }
              );
            });
          }
        })
      )
    );
  };

  handlerRouteScreen = (e, isStep3 = false) => {
    let data = e.row.data;
    displayPreload(true);
    Promise.all([
      this.teams(data.RouteId),
      this.tasks(data.RouteId),
      this.treeListData(data.RouteId),
      this.activityCreated(data.RouteId),
    ]).then(() => {
      let tasksDS = this.state.tasksDS;
      let treeListData = this.state.treeListData;

      let items = treeListData.filter((j) => j.Level === 5 && j.Selected);

      tasksDS.forEach((j) => {
        let temp =
          items.find(
            (i) =>
              i.Line === j.Line &&
              i.MasterUnit === j.MasterUnit &&
              i.SlaveUnit === j.SlaveUnit &&
              i.Group === j.Group &&
              i.ItemDesc === j.Task
          )?.ItemId ?? -1;

        if (temp !== -1) j.ItemId = temp;
      });

      let containersHeight =
        document.getElementById("cdrRoutesMgmt")?.offsetHeight;

      this.setState(
        {
          displayRouteScreen: true,
          routeDescSelected: data.RouteDescription,
          routeSelected: data,
          tasksDS,
          containersHeight: containersHeight
            ? containersHeight - 280 + "px"
            : "",
        },
        () => {
          setTimeout(() => {
            this.refGridTasks.current?.instance.selectAll();
          }, 450);
          if (isStep3) {
            this.handleStep3(data);
          } else {
            this.refAccordion.current?.instance.collapseItem(0);
            this.refAccordion.current?.instance.expandItem(1);
            let refTreeList = this.refTreeList?.current;
            if (refTreeList !== null) refTreeList.instance.refresh();
            displayPreload(false);
            setTimeout(() => {
              this.refTreeList.current?.instance.repaint();
              this.refTreeList.current?.instance.refresh();
            }, 250);
          }
        }
      );
    });
  };

  handlerAddRoute = () => {
    let grid = this.refGridRoutes.current?.instance;
    grid.addRow();
  };

  handlerAddTourStop = () => {
    let grid = this.refGridTourStopsListAdded.current?.instance;
    grid.addRow();
  };

  handlerDeleteRoutes = () => {
    const { t } = this.props;
    let grid = this.refGridRoutes.current?.instance;
    let data = grid.getSelectedRowsData();

    if (data.length === 0) {
      warning(this.props.t("Please, select at least one Route"));
      return;
    }

    let dialog = confirm(
      `<span>You are about to delete ${data.length} route/s. Are you sure?</span>`,
      t("Delete Route/s")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        displayPreload(true);
        deleteRoutes(data.map((m) => m.RouteId).join(",")).then(() =>
          this.reloadRoutes()
        );
      }
    });
  };

  sectionsUpdate = () => {
    let currentDesc = this.state.routeSelected.RouteDescription;
    var updateDesc = document.querySelector("[name=routeDescSelected]").value;
    this.refGridTeams.current?.instance.refresh();

    let isRouteDescUpdate = currentDesc !== updateDesc;
    let key = "TeamId";
    let team1 = this.state.teamsDS.filter((f) => f.Selected);
    let team2 = this.refGridTeams.current?.instance.getSelectedRowsData();
    let isTeamsUpdate =
      team2 !== undefined &&
      getKeySorted(team1, key) !== getKeySorted(team2, key);

    let task1 = this.refGridTasks.current?.instance.getSelectedRowsData();
    task1 = task1 === undefined ? this.state.tasksLoaded : task1;

    // This line is to solve temporary the issue 1081 from Panaya
    // Error while updating some of the existing Routes
    let task2 = this.state.tasksLoaded.filter((task) => task.ItemId !== -1);

    let isTasksUpdate = JSON.stringify(task1) !== JSON.stringify(task2);

    return {
      isRouteDescUpdate,
      isTeamsUpdate,
      isTasksUpdate,
    };
  };

  routeDescriptionIsEmpty = () => {
    return document.querySelector("[name=routeDescSelected]").value === "";
  };

  handlerExportToPDF = async (view) => {
    let fileName = view === "Routes" ? "gvSummary.pdf" : "gvView.pdf";

    let ref =
      view === "Routes"
        ? this.refGridRoutes
        : view === "Teams"
        ? this.refGridTeams
        : view === "AllRoute-Teams"
        ? this.refGridAllTeams
        : view === "AllRoute-Tasks"
        ? this.refGridAllTasks
        : this.refGridTasks;

    let columns = Array(
      ref.current?.instance
        .getVisibleColumns()
        .filter(
          (col) =>
            col.visible &&
            col.type !== "buttons" &&
            col.type !== "selection" &&
            col.type !== "drag"
        )
        // eslint-disable-next-line no-sequences
        .reduce((obj, item) => ((obj[item.dataField] = item.caption), obj), {})
    );

    let instance = ref.current?.instance;
    let data = [];
    if (view === "AllRoute-Teams" || view === "AllRoute-Tasks")
      data = instance.getDataSource().store()._array;
    else if (view === "Routes")
      data = instance.getCombinedFilter()
        ? instance.getDataSource()._items
        : instance.getDataSource().store()._array;
    else data = instance.getSelectedRowsData();
    this.exportToPDF(columns, data, fileName);
  };

  exportToPDF = (columns, data, fileName) => {
    var document = generateExportDocument(columns, data);
    document.save(fileName);
  };

  handlerExportToExcel = (view) => {
    let ref =
      view === "Routes"
        ? this.refGridRoutes
        : view === "Teams"
        ? this.refGridTeams
        : view === "AllRoute-Teams"
        ? this.refGridAllTeams
        : view === "AllRoute-Tasks"
        ? this.refGridAllTasks
        : this.refGridTasks;
    ref.current?.instance.exportToExcel(
      view === "Teams" || view === "Tasks" ? true : false
    );
  };

  onAddRoute(e) {
    let routesDS = this.state.routesDS;
    displayPreload(true);
    if (e.data.RouteDescription !== undefined) {
      let newRoute = {
        RouteDesc: e.data.RouteDescription,
      };
      if (
        routesDS?.filter(
          (route) =>
            route.RouteDescription.toLowerCase() ===
            newRoute.RouteDesc.toLowerCase()
        ).length === 0
      ) {
        //Check that route description doesn't already exist
        addRoute(newRoute).then(() => {
          this.reloadRoutes();
        });
      } else {
        this.reloadRoutes();
        error(this.props.t("This route description already exists"));
      }
    } else {
      warning(this.props.t("You must enter a description"));
    }
  }

  onAddTourStop(e) {
    let tourStopsList = this.state.tourStopsList;
    let TourDesc = e.data.TourDesc;
    if (TourDesc !== undefined) {
      if (
        tourStopsList?.filter(
          (stop) => stop.TourDesc.toLowerCase() === TourDesc.toLowerCase()
        ).length === 0
      ) {
        //Check that tour description doesn't already exist
        AddTourStop({
          TourDesc,
          RouteId: this.state.routeSelected.RouteId,
        }).then((TourId) => {
          let first = {
            TourId,
            TourDesc,
          };
          tourStopsList.push(first);
          setTimeout(() => {
            this.handleStep3();
          }, 200);
        });
      } else {
        setTimeout(() => {
          this.handleStep3();
        }, 200);
        error(this.props.t("This tour stop name already exists"));
      }
    } else {
      warning(this.props.t("You must enter a name"));
    }
  }

  keepSelectedRoute = (refGridRoutes) => {
    let selected = refGridRoutes.getSelectedRowKeys();
    if (!selected.length) return;
    let selectedId = refGridRoutes.getRowIndexByKey(selected[0]);
    refGridRoutes.selectRowsByIndexes(selectedId);
  };

  onUpdateRoute = (route) => {
    let {
      step2_WasUpdated,
      step2RouteDescUpdate,
      step2_TasksWasUpdated,
      step3_WasUpdated,
      step4_WasUpdated,
      step3Tasks_WasUpdated,
      showActivityValue,
      step3AlreadyLoaded,
      activityWasUpdated,
      isIntegratedRouteState,
      CheckIfRouteHasQRState,
    } = this.state;
    let RouteId = this.state.routeSelected.RouteId;
    let routeDesc = document.querySelector("[name=routeDescSelected]").value;
    let tasksDSItemsIds =
      this.refGridTasks?.current?.instance.getSelectedRowKeys();
    let updatedRoute = {
      RouteId: route.RouteId,
      Key: route.RouteId,
      RouteDesc: routeDesc,
      NbrTeams: route.NbrTeams,
      NbrTasks: route.NbrTasks,
    };
    let newActivityRoute = {
      RouteId: RouteId,
      RouteDesc: routeDesc,
      isCreateActivity: showActivityValue,
      activityTrigger: 1,
    };
    let refGridRoutes = this.refGridRoutes.current?.instance;
    displayPreload(true);

    // ## handlerRouteDescription
    if (step2RouteDescUpdate) {
      if (routeDesc !== "") {
        //Check that new route description isn't empty
        let routesDS = this.state.routesDS;
        if (
          routesDS?.filter(
            (route) =>
              route.RouteDescription.toLowerCase() === routeDesc.toLowerCase()
          ).length === 0
        ) {
          //Check that route description doesn't already exist
          updateRoute(updatedRoute).then((res) => {
            if (res.status !== 200) {
              newActivityRoute.RouteDesc = route.RouteDescription;
              document.querySelector("[name=routeDescSelected]").value =
                route.RouteDescription;
            }
            if (showActivityValue) {
              UpdateSheetDesc(newActivityRoute).then(() => {});
            }
            this.setState(
              {
                step2_WasUpdated: false,
                step2RouteDescUpdate: false,
                activityWasUpdated: false,
              },
              () => {
                if (
                  !step2_WasUpdated &&
                  !step3_WasUpdated &&
                  !step3Tasks_WasUpdated
                ) {
                  this.refreshRoutes();
                }
              }
            );
          });
        } else {
          //Handle route description already existing
          error(this.props.t("This route description already exists"));
          document.querySelector("[name=routeDescSelected]").value =
            route.RouteDescription;
          this.refreshRoutes();
          return; //Don't update the rest of the route
        }
      } else {
        //Handle route description being empty
        warning(this.props.t("You must enter a description"));
        document.querySelector("[name=routeDescSelected]").value =
          route.RouteDescription;
        this.refreshRoutes();
        return; //Don't update the rest of the route
      }
    }

    if (activityWasUpdated) {
      let url = window.location.href.toString().toLowerCase().replace("/#", "");
      createRouteDisplay(newActivityRoute, url).then(() => {});
    }

    if (step2_TasksWasUpdated) {
      let routeData = {
        RouteId: RouteId,
        IdList: tasksDSItemsIds.join(","),
      };
      updataRouteTasksAssociations(routeData).then(async () => {
        let messageAdding =
          "It looks like you have added one or more centerline task(s) associated with this route. To ensure accurate information, please re-print the QR code linked to this route.";
        let messageRemoving =
          "It looks like you have removed all centerline tasks associated with this route. To ensure accurate information, please re-print the QR code linked to this route.";

        let newValueForIntegratedRoute = await IsIntegratedRoute(RouteId);

        if (
          isIntegratedRouteState !== newValueForIntegratedRoute &&
          CheckIfRouteHasQRState
        )
          alert(
            !isIntegratedRouteState && newValueForIntegratedRoute
              ? messageAdding
              : messageRemoving
          );
        if (showActivityValue)
          await updateDisplayVariablesAssociations(routeData);

        this.setState(
          {
            step2_WasUpdated: false,
            step2RouteDescUpdate: false,
            step2_TasksWasUpdated: false,
            activityWasUpdated: false,
            routeSelected: {
              ...this.state.routeSelected,
              RouteDescription: routeDesc,
            },
          },
          () => {
            if (step3AlreadyLoaded) this.handleStep3();
            if (step3_WasUpdated || step3Tasks_WasUpdated)
              this.onUpdateRoute(route);
            else {
              this.refreshRoutes();
            }
            this.keepSelectedRoute(refGridRoutes);
            this.refTreeList.current?.instance.refresh();
            this.refAccordion.current?.instance.expandItem(1);
            localStorage.removeItem("hasUpdates");
          }
        );
      });
    }

    if ((step3_WasUpdated || step3Tasks_WasUpdated) && !step2_WasUpdated) {
      this.onSaveTourStop();
    }

    if (step4_WasUpdated) {
      let data = this.refGridTeams.current?.instance.getSelectedRowsData();
      updataRouteTeamsAssociations({
        RouteId: this.state.routeSelected.RouteId,
        IdList: data.map((m) => m.TeamId).join(","),
      }).then(() => {
        this.teams(RouteId);
        this.setState(
          {
            step4_WasUpdated: false,
          },
          () => {
            this.keepSelectedRoute(refGridRoutes);
            if (
              !step2_WasUpdated &&
              !step3_WasUpdated &&
              !step3Tasks_WasUpdated
            ) {
              this.refreshRoutes();
              localStorage.removeItem("hasUpdates");
            }
          }
        );
      });
    }

    setTimeout(() => {
      if (this.state.stepWasUpdated) {
        this.refreshRoutes();
      }
    }, 3000);
  };

  refreshRoutes = () => {
    getRoutes().then((response) => {
      this.setState(
        {
          stepWasUpdated: false,
          routesDS: response,
        },
        () => displayPreload(false)
      );
    });
  };

  changeRowsForPageTasks = (e) => {
    let refGridTasks = this.refGridTasks.current?.instance;
    refGridTasks.option("paging.pageSize", e.value);
  };

  toolbarItemRender() {
    const { t } = this.props;
    return (
      <div className="informer">
        <span className="name">{t("Number of Rows per page")}:</span>
      </div>
    );
  }

  onTreeListItemClick = (e) => {
    var temp = e.component
      .getDataSource()
      ._store._array.find((f) => f.Id === e.key);

    if (temp !== undefined) {
      let item = temp.data === undefined ? temp : temp.data;
      if (item.Level === 1 && !this.state.linesLoaded.includes(item.ItemDesc)) {
        displayPreload(true);
        buildTreeListItems(item, this.state, false).then((response) => {
          const { tempLinesLoaded, newTreeListData } = response;
          this.setState(
            {
              linesLoaded: tempLinesLoaded,
              treeListData: newTreeListData,
            },
            () => {
              this.refTreeList.current?.instance.refresh();
              this.refGridTasks.current?.instance.refresh();
              displayPreload(false);
            }
          );
        });
      }
    }
  };

  onSelectionChangedHanlder = (e) => {
    let elem = [];
    let refGridTasks = this.refGridTasks.current?.instance;
    var tasksDStemp = refGridTasks.getDataSource()._store._array || [];
    let treeListData = this.state.treeListData;
    if (e.currentSelectedRowKeys.length > 0) {
      displayPreload(true);
      let treeItem = e.component
        .getSelectedRowsData()
        .find((f) => f.Id === e.selectedRowKeys[e.selectedRowKeys.length - 1]);

      if (
        treeItem.Level === 1 &&
        !this.state.linesLoaded.includes(treeItem.ItemDesc)
      ) {
        buildTreeListItems(treeItem, this.state, false).then((response) => {
          const { tempLinesLoaded, newTreeListData } = response;
          this.setState(
            {
              linesLoaded: tempLinesLoaded,
              treeListData: newTreeListData,
            },
            () => {
              this.refTreeList.current?.instance.refresh();
              refGridTasks.refresh();

              let itemSelected = [treeItem];
              let level = treeItem.Level;

              elem = treeListTasksSelected(level, itemSelected, treeListData);

              elem.forEach((item) => {
                if (!tasksDStemp.find((f) => f.ItemId === item.ItemId)) {
                  tasksDStemp.push({
                    Line: item.Line,
                    MasterUnit: item.MasterUnit,
                    SlaveUnit: item.SlaveUnit,
                    Group: item.Group,
                    Task: item.ItemDesc,
                    TaskOrder: tasksDStemp.length + 1,
                    ItemId: item.ItemId,
                  });
                }
              });

              setTimeout(() => {
                refGridTasks.getDataSource()._store._array = tasksDStemp;
                refGridTasks.refresh();
                displayPreload(false);
              }, 250);
            }
          );
        });
      } else {
        let itemId = e.currentSelectedRowKeys[0];
        let itemSelected = e.selectedRowsData.filter((f) => f.Id === itemId);
        let level = itemSelected[0].Level;

        elem = treeListTasksSelected(level, itemSelected, treeListData);

        elem.forEach((item) => {
          if (!tasksDStemp.find((f) => f.ItemId === item.ItemId)) {
            tasksDStemp.push({
              Line: item.Line,
              MasterUnit: item.MasterUnit,
              SlaveUnit: item.SlaveUnit,
              Group: item.Group,
              Task: item.ItemDesc,
              TaskOrder: tasksDStemp.length + 1,
              ItemId: item.ItemId,
              TourDesc: "Unassigned",
            });
          }
        });

        setTimeout(() => {
          refGridTasks.getDataSource()._store._array = tasksDStemp;
          refGridTasks.refresh();
          displayPreload(false);
        }, 250);
      }
    } else if (e.currentDeselectedRowKeys.length > 0) {
      let itemId = e.currentDeselectedRowKeys[0];
      let itemDeselected = treeListData.find((item) => item.Id === itemId);
      if (itemDeselected !== undefined) {
        let level = itemDeselected.Level;

        displayPreload(true);
        elem = treeListTasksSelected(level, [itemDeselected], treeListData);
        elem.forEach((item) => {
          var ind = tasksDStemp.findIndex((e) => e.ItemId === item.ItemId);
          tasksDStemp.splice(ind, 1);
        });
        displayPreload(false);
      }
    }
    refGridTasks.refresh();
  };

  backFromAllRoutesTeams = () => {
    this.setState({
      displayAllRouteTeams: false,
    });
  };

  backFromAllRoutesTasks = () => {
    this.setState({
      displayAllRouteTasks: false,
    });
  };

  onRowPrepared = (e) => {
    if (e.rowType === "data") {
      if (e.data.ItemId === -1) e.rowElement.classList.add(`grid-row-defect`);
    }
  };

  onActivityViewerValueChanged = (e) => {
    if (!e.event) return;
    this.setState(
      {
        [e.tag]: e.value,
        stepWasUpdated: true,
        step2_WasUpdated: true,
        activityWasUpdated: true,
      },
      () => localStorage.setItem("hasUpdates", "true")
    );
  };

  nextStep = async (step) => {
    let refGridRoutes = this.refGridRoutes.current?.instance;
    let selectedRowKeys = refGridRoutes
      ? refGridRoutes.getSelectedRowsData()
      : this.state.routeSelected;
    if (!selectedRowKeys.length) {
      warning("Select at least one Route please");
      return false;
    }
    if (step === 0) {
      // TO STEP 2
      if (!this.state.step2AlreadyLoaded) {
        let [isIntegratedRouteState, CheckIfRouteHasQRState] =
          await Promise.all([
            IsIntegratedRoute(selectedRowKeys[0].RouteId),
            CheckIfRouteHasQR(selectedRowKeys[0].RouteId),
          ]);
        this.setState({ isIntegratedRouteState, CheckIfRouteHasQRState });
        this.handlerRouteScreen({ row: { data: selectedRowKeys[0] } }, true);
        this.refAccordion.current?.instance.collapseItem(1);
        setTimeout(() => {
          this.refTreeList.current?.instance.refresh();
          this.refAccordion.current?.instance.expandItem(1);
        }, 200);
      } else {
        this.refTreeList.current?.instance.refresh();
        this.refAccordion.current?.instance.expandItem(1);
      }
    } else if (step === 1) {
      // TO STEP 3
      if (!this.state.step2AlreadyLoaded) {
        this.handlerRouteScreen({ row: { data: selectedRowKeys[0] } }, true);
      } else if (!this.state.step3AlreadyLoaded)
        this.handleStep3(selectedRowKeys[0]);
      else {
        this.setState({
          tourStopTasks:
            this.refGridTasks.current?.instance.getSelectedRowsData(),
        });
      }
    } else if (step === 2) {
      // TO STEP 4
      if (!this.state.step4AlreadyLoaded) {
        displayPreload(true);
        this.teams(selectedRowKeys[0].RouteId).then((teamsDS) => {
          let varIds = teamsDS.filter((f) => f.Selected).map((m) => m.TeamId);
          if (!varIds) return;
          this.setState(
            {
              routeSelected: selectedRowKeys[0],
              step4AlreadyLoaded: true,
            },
            () => {
              let { getRowIndexByKey, selectRowsByIndexes, deselectAll } =
                this.refGridTeams.current?.instance;
              deselectAll();
              let indexes = [];
              setTimeout(() => {
                varIds.forEach((varId) => {
                  let id = getRowIndexByKey(varId);
                  indexes.push(id);
                });
                selectRowsByIndexes(indexes);
                displayPreload(false);
              }, 500);
            }
          );
        });
      }
    }
    return true;
  };

  handleStep3 = (selectedRow = null) => {
    let { routeSelected, tourStopTasks } = this.state;
    let refGridTasksStep2 = this.refGridTasks.current?.instance;
    routeSelected = Object.keys(routeSelected).length
      ? routeSelected
      : selectedRow;

    displayPreload(true);
    getTourStopInfo(routeSelected.RouteId).then((response) => {
      getTourStop(routeSelected.RouteId).then((resp) => {
        if (!response) return;

        if (refGridTasksStep2?.getSelectedRowsData())
          tourStopTasks = refGridTasksStep2?.getSelectedRowsData();
        else tourStopTasks = this.state.tasksDS;

        tourStopTasks.forEach((t) => {
          t.TourId = "";
          t.isAdded = false;
          t.TourDesc = "";
        });

        tourStopTasks.forEach((t) => {
          let temp = response.find((ts) => ts.VarId === t.ItemId);
          if (temp) t.TourTaskOrder = temp?.TourTaskOrder;
          t.TourDesc = t.TourDesc !== "" ? t.TourDesc : "Unassigned";
        });

        resp.forEach((x) => {
          let TourId = x.TourId;
          let VarIds = [];
          response.forEach((y) => {
            if (y.TourId === TourId) {
              VarIds.push(y.VarId);
            }
          });
          x.VarIds = VarIds.join();
        });

        resp.forEach((x) => {
          x.VarIds.split(",").forEach((y) => {
            let temp = this.state.tasksDS.find((z) => z.ItemId === parseInt(y));
            if (temp) {
              temp.TourId = x.TourId;
              temp.isAdded = true;
              temp.TourDesc = "(" + x.TourOrder + ") " + x.TourDesc;
            }
          });
        });

        sortBy("asc", tourStopTasks, "TourTaskOrder");

        this.setState(
          {
            tourStopsList: resp,
            tourStopTasks,
            step3AlreadyLoaded: true,
          },
          () => {
            setTimeout(() => {
              refGridTasksStep2?.refresh();
            }, 200);
            setTimeout(() => {
              this.refGridTourStops.current?.instance.columnOption(
                "TourDesc",
                "groupIndex",
                1
              );
              this.refGridTourStopsListAdded.current?.instance.refresh();
              this.refGridTourStops.current?.instance.refresh();
              displayPreload(false);
            }, 600);
          }
        );
      });
    });
  };

  handleSelectTourStopRemoving = (value) => {
    let TourStop = {};
    TourStop.routeId = this.state.routeSelected.RouteId;
    TourStop.tourId = value.row.data.TourId;
    const { t } = this.props;

    displayPreload(true);
    getTourMapImageCount(value.row.data.TourMap || "").then((response) => {
      let message = "";
      if (response === 1) {
        message =
          "This will delete TourStop and associated Tour Map image. Are you sure you want to delete?";
      } else {
        message = "This will delete TourStop. Are you sure you want to delete?";
      }

      let dialog = confirm(
        `<span>` + t(message) + `</span>`,
        t("Delete Tour Stop")
      );

      dialog.then((dialogResult) => {
        if (dialogResult) {
          deleteTourStop(TourStop).then(() => {
            this.handleStep3();
            this.refGridTourStops.current?.instance?.deselectAll();
          });
        }
      });
      displayPreload(false);
    });
  };

  handleSelectTourStop = (e) => {
    let refGridTourStopsListAdded =
      this.refGridTourStopsListAdded?.current?.instance;
    if (!e.currentSelectedRowKeys?.length) return;
    let currentDeselectedRowKeys = e.currentDeselectedRowKeys[0];
    displayPreload(true);
    setTimeout(() => {
      this.selectingTourStop(e);
      if (this.state.step3Tasks_WasUpdated === true) {
        let dialog = confirm(
          `<span>You have changes without save, do you want to continue without saving?</span>`,
          "Unsaved changes"
        );
        dialog.then((dialogResult) => {
          if (dialogResult) {
            this.setState(
              {
                step3Tasks_WasUpdated: false,
                isCheckedAll: false,
                taskIdsTourStop: [],
              },
              () => {
                if (
                  !this.state.step2_WasUpdated &&
                  !this.state.step4_WasUpdated
                )
                  localStorage.removeItem("hasUpdates");
                this.selectingTourStop(e);
              }
            );
          } else {
            let index = refGridTourStopsListAdded.getRowIndexByKey(
              currentDeselectedRowKeys
            );

            this.setState(
              {
                step3Tasks_WasUpdated: false,
                isCheckedAll: false,
                taskIdsTourStop: [],
              },
              () => refGridTourStopsListAdded.selectRowsByIndexes(index)
            );
            return;
          }
        });
      }
    }, 250);
  };

  selectingTourStop = async (e) => {
    let {
      getRowIndexByKey,
      selectRowsByIndexes,
      pageSize,
      pageIndex,
      pageCount,
      getDataSource,
      deselectAll,
    } = this.refGridTourStops.current?.instance;
    let indexes = [];
    displayPreload(true);
    pageSize(1000);
    let varIds = e.selectedRowsData[0]?.VarIds;
    varIds = varIds ? varIds.split(",") : [];
    pageIndex() !== 0 && pageIndex(0);
    deselectAll();

    setTimeout(() => {
      varIds.forEach((varId) => {
        indexes.push(getRowIndexByKey(parseInt(varId)));
      });
      selectRowsByIndexes(indexes);
    }, 250);

    setTimeout(() => {
      pageSize(30);
      displayPreload(false);
    }, 500);

    setTimeout(() => {
      for (let index = 0; index < pageCount(); index++) {
        setTimeout(async () => {
          if (varIds.length) {
            let isInThisPage =
              getRowIndexByKey(parseInt(varIds[varIds.length - 1])) !== -1;
            if (!isInThisPage) pageIndex(index + 1);
          } else {
            let isUnassignedPage = getDataSource()
              .items()
              .some((x) => x.key === "Unassigned");
            if (!isUnassignedPage) pageIndex(index + 1);
            else if (isUnassignedPage) {
              setTimeout(() => {
                selectRowsByIndexes([0, 1, 2, 5]);
              }, 100);
              setTimeout(() => {
                deselectAll();
              }, 200);
            }
          }
        }, index * 150);
      }
    }, 750);
  };

  onSaveTourStop = () => {
    let tour = {};
    tour.RouteId = this.state.routeSelected.RouteId;
    let grid_Tasks = this.refGridTourStops?.current?.instance;
    let grid_TS = this.refGridTourStopsListAdded?.current?.instance;
    let { step2RouteDescUpdate, step2_WasUpdated, step4_WasUpdated } =
      this.state;
    let tourIdsOrder = grid_TS
      .getDataSource()
      ._store._array.map((y) => y.TourId)
      .join();
    if (grid_TS.getSelectedRowsData().length) {
      tour.TourId = grid_TS.getSelectedRowsData()[0].TourId;
    }
    tour.TaskIds = grid_Tasks.getSelectedRowKeys().join();
    tour.tourIdsOrder = tourIdsOrder;
    displayPreload(true);
    updatetourstoptasks(tour).then(() => {
      this.handleStep3(grid_TS.getSelectedRowsData()[0]);
      this.setState(
        {
          step3_WasUpdated: false,
          step3Tasks_WasUpdated: false,
        },
        () => {
          let refGridRoutes = this.refGridRoutes.current?.instance;
          this.keepSelectedRoute(refGridRoutes);
          if (!step2RouteDescUpdate && !step2_WasUpdated && !step4_WasUpdated) {
            this.refreshRoutes();
            localStorage.removeItem("hasUpdates");
          }
          displayPreload(false);
        }
      );
      // });
    });
  };

  handleSelectTasks_TS = (e) => {
    let tourStopSelected =
      this.refGridTourStopsListAdded.current?.instance.getSelectedRowKeys()[0];
    let refGridTS = this.refGridTourStops.current?.instance;
    let tasks = refGridTS.getDataSource()._store._array;
    let VarIdSelected = e.currentSelectedRowKeys[0];
    if (!VarIdSelected) {
      return;
    }

    tasks.forEach((x) => {
      if (x.TourId !== tourStopSelected && x.TourId) x.isAdded = true;
      else {
        x.isAdded = false;
      }
    });
    refGridTS.getDataSource()._store._array = tasks;
    refGridTS.refresh();
  };

  saveFunction = () => {
    let routeSelected = this.state.routeSelected;
    this.onUpdateRoute(routeSelected);
    localStorage.removeItem("hasUpdates");
  };

  handleUpdateTourStopDesc = (val) => {
    let refGrid = this.refGridTourStopsListAdded.current?.instance;
    let newDesc = val.newData.TourDesc;
    let oldDesc = val.oldData.TourDesc;
    let tourStopsList = this.state.tourStopsList;
    let TourStop = {
      tourDesc: newDesc,
      tourId: val.oldData.TourId,
      routeId: this.state.routeSelected.RouteId,
    };
    if (newDesc !== oldDesc) {
      if (
        tourStopsList?.filter(
          (stop) => stop.TourDesc.toLowerCase() === newDesc.toLowerCase()
        ).length === 0
      ) {
        //Check that the tour stop name doesn't already exist
        updateTourStopDesc(TourStop).then(() => {
          refGrid.refresh();
        });
      } else {
        //Handle tour stop already existing
        error(this.props.t("This tour stop name already exists"));
        setTimeout(() => {
          this.handleStep3();
        }, 200);
      }
    }
  };

  handleSelectRoute = (e) => {
    let refAccordion = this.refAccordion.current?.instance;
    let refTreeList = this.refTreeList.current?.instance;

    if (
      this.state.step2AlreadyLoaded ||
      this.state.step3AlreadyLoaded ||
      this.state.step4AlreadyLoaded
    ) {
      this.setState(
        {
          disableNextButton: false,
          step2AlreadyLoaded: false,
          step3AlreadyLoaded: false,
          step4AlreadyLoaded: false,
          stepWasUpdated: false,
          step2_WasUpdated: false,
          step2_TasksWasUpdated: false,
          step3_WasUpdated: false,
          step4_WasUpdated: false,
          step3Tasks_WasUpdated: false,
          expandedRowKeys: [],
          selectedRowKeys: [],
          tasksDS: [],
          treeListData: [],
          activityWasUpdated: false,
        },
        () => {
          this.refGridTourStops.current?.instance.deselectAll();
          this.refGridTourStopsListAdded.current?.instance.deselectAll();
          refTreeList?.refresh();
          refAccordion.expandItem(0);
          refAccordion.collapseItem(1);
          localStorage.removeItem("hasUpdates");
        }
      );
    } else {
      this.setState({
        disableNextButton: e.selectedRowsData.length !== 1,
      });
    }
  };

  onEditorPreparing_TS_Tasks = (e) => {
    let tsGrid = this.refGridTourStopsListAdded?.current?.instance;
    if (e.parentType === "dataRow" && tsGrid) {
      let row = e.editorElement.parentElement.parentElement;
      row.style.backgroundColor = "#fff";
      let TourID = tsGrid.getSelectedRowKeys()[0];
      let checkBox = e.editorElement;
      let data = e.row.data;
      if (data.isAdded && data.TourId !== TourID) {
        row.style.backgroundColor = "#ededed";
        row.title = "The task is already assigned to a tour stop.";
        checkBox.style.display = "none";
      } else if (!data.isAdded) {
        row.style.backgroundColor = "#FFF";
        row.title = "";
        checkBox.style.display = "contents";
      }
    }
  };

  handlerTaskStep2CellClick = (e) => {
    let newSelectedTasks =
      this.refGridTasks.current?.instance.getSelectedRowsData();

    if (e.text === "" || e?.rowType?.includes("header")) {
      this.setState(
        {
          stepWasUpdated: true,
          step2_WasUpdated: true,
          step2_TasksWasUpdated: true,
          tourStopTasks: newSelectedTasks,
        },
        () => {
          this.refGridTourStops.current?.instance.refresh();
          localStorage.setItem("hasUpdates", "true");
        }
      );
    }
  };

  stepWasUpdatedMethod = (val) => {
    this.setState({
      stepWasUpdated: val,
    });
  };

  step3_WasUpdated = (val) => {
    this.setState({
      stepWasUpdated: true,
      step3_WasUpdated: val,
    });
    localStorage.setItem("hasUpdates", "true");
  };

  onTasksCellClick = (e) => {
    const { t } = this.props;
    let { isCheckedAll } = this.state;
    let refGridTourStopsListAdded =
      this.refGridTourStopsListAdded.current?.instance;
    let selectedRowKeys = refGridTourStopsListAdded?.getSelectedRowKeys();
    let selectedRowData = refGridTourStopsListAdded?.getSelectedRowsData();
    let { getRowIndexByKey, selectRowsByIndexes, deselectAll, getDataSource } =
      this.refGridTourStops.current?.instance;

    if (e.rowType === "header") {
      if (!selectedRowKeys.length) {
        warning(t("Please, select at least one tour stop"));
        deselectAll();
        return;
      }

      if (!isCheckedAll) {
        let indexes = [];
        let resultDataSource = [];
        let unassignedItems = e.component
          .getDataSource()
          ._items.filter((x) => x.key === "Unassigned");

        let alreadyIds = getDataSource()
          ._store._array.filter((x) => x.TourId === selectedRowKeys[0])
          .map((y) => y.ItemId);
        if (unassignedItems.length)
          unassignedItems = unassignedItems[0].items.map((y) => y.ItemId);

        resultDataSource = unassignedItems.concat(
          e.component.getSelectedRowKeys().length
            ? e.component.getSelectedRowKeys()
            : alreadyIds
        );

        resultDataSource.forEach((ItemId) => {
          let id = getRowIndexByKey(ItemId);
          indexes.push(id);
        });

        selectRowsByIndexes(resultDataSource.length ? indexes : -1);
        this.setState(
          {
            stepWasUpdated: true,
            step3Tasks_WasUpdated: true,
            isCheckedAll: true,
            taskIdsTourStop: selectedRowKeys,
          },
          () => localStorage.setItem("hasUpdates", "true")
        );
      } else {
        deselectAll();
        this.setState({
          isCheckedAll: false,
        });
      }
    }

    if (e.text === "" && e.rowType === "data") {
      if (!selectedRowKeys.length) {
        warning(t("Please, select at least one tour stop"));
        deselectAll();
        return;
      } else if (e.data.isAdded && e.data.TourId !== selectedRowKeys[0]) {
        warning(t("This task is already assigned to a tour stop"));
        this.handleSelectTourStop({
          selectedRowsData: [
            {
              VarIds: selectedRowData[0].VarId,
            },
          ],
        });
        return;
      } else {
        this.setState(
          {
            stepWasUpdated: true,
            step3Tasks_WasUpdated: true,
          },
          () => localStorage.setItem("hasUpdates", "true")
        );
      }
    }
  };

  handlerAllRouteTeams = () => {
    displayPreload(true);
    getReportAllRouteTeams().then((response) =>
      this.setState(
        {
          displayAllRouteTeams: true,
          allRouteTeamsDS: response,
          disableNextButton: true,
        },
        () => {
          setTimeout(() => {
            this.refGridAllTeams.current?.instance.columnOption(
              "Route",
              "groupIndex",
              1
            );
            displayPreload(false);
          }, 300);
        }
      )
    );
  };

  handlerAllRouteTasks = () => {
    displayPreload(true);
    getReportAllRouteTasks().then((response) =>
      this.setState(
        {
          displayAllRouteTasks: true,
          allRouteTasksDS: response,
          disableNextButton: true,
        },
        () => {
          displayPreload(false);
        }
      )
    );
  };

  activityCreated = (routeId) => {
    return new Promise((resolve) =>
      resolve(
        getReportRouteActivity(routeId).then((response) => {
          this.setState({
            showActivityStored: response.IsCreateActivity,
            showActivityValue: response.IsCreateActivity,
          });
        })
      )
    );
  };

  hasCLTasks = (tasks) => {
    if (!tasks) return;
    return tasks.some((x) => x?.EventSubtypeDesc !== "eCIL");
  };

  render() {
    let {
      tourStopsList,
      routesDS,
      teamsDS,
      tasksDS,
      routeSelected,
      treeListData,
      selectedRowKeys,
      expandedRowKeys,
      scrollingMode,
      containersHeight,
      showSavePopup,
      tourStopSelected,
      step2_WasUpdated,
      step3_WasUpdated,
      step3Tasks_WasUpdated,
      step4_WasUpdated,
      disableNextButton,
      tourStopTasks,
      displayAllRouteTeams,
      allRouteTeamsDS,
      displayAllRouteTasks,
      allRouteTasksDS,
      columnsTaskGrid_Step3,
      showActivityValue,
      activityWasUpdated,
      step2RouteDescUpdate,
    } = this.state;
    const { t } = this.props;
    const globalAccessLevel = getUserRole();

    return (
      <Card id="cdrRoutesMgmt" autoHeight>
        <div className={[styles.container].join(" ")}>
          <MyStepper
            t={t}
            events={this.nextStep}
            saveFunction={this.saveFunction}
            disableNextButton={disableNextButton}
            stepWasUpdated={
              step2_WasUpdated ||
              step3_WasUpdated ||
              step4_WasUpdated ||
              activityWasUpdated ||
              step2RouteDescUpdate ||
              step3Tasks_WasUpdated
            }
          >
            {/* STEP 1 */}
            <div
              className={styles.step}
              style={{
                height:
                  document.getElementById("cdrRoutesMgmt")?.offsetHeight -
                  170 +
                  "px",
              }}
            >
              {!displayAllRouteTasks && !displayAllRouteTeams ? (
                <>
                  <DataGrid
                    identity="grdRoutesMgmt"
                    keyExpr="RouteId"
                    reference={this.refGridRoutes}
                    dataSource={routesDS}
                    showBorders={false}
                    rowAlternationEnabled={false}
                    columns={gridRoutesColumns()}
                    onRowInserting={this.onAddRoute.bind(this)}
                    filterRow={true}
                    onSelectionChanged={this.handleSelectRoute}
                    onToolbarPreparing={(e) =>
                      gridRoutesToolbarPreparing(
                        e,
                        t,
                        globalAccessLevel,
                        this.handlerAddRoute,
                        this.handlerDeleteRoutes,
                        this.handlerAllRouteTeams,
                        this.handlerAllRouteTasks,
                        this.handlerExportToPDF,
                        this.handlerExportToExcel
                      )
                    }
                    onEditorPreparing={(e) => {
                      //Limits the number of characters route description can be
                      if (
                        e.parentType === "dataRow" &&
                        e.dataField === "RouteDescription"
                      ) {
                        e.editorOptions.maxLength = 150;
                      }
                    }}
                  >
                    <Column
                      type="buttons"
                      buttons={[
                        {
                          name: "edit",
                          icon: getIcon(icons.gridEdit), // icons.gridEdit,
                          hint: t("Edit"),
                        },
                      ]}
                      cssClass={styles.btnGridButtons}
                      width="60px"
                    />
                    <Export fileName="gvSummary" />
                    <Editing
                      mode="row"
                      useIcons={true}
                      allowUpdating={false}
                      allowAdding={false}
                      allowDeleting={true}
                    />

                    <Selection mode="multiple" showCheckBoxesMode="onClick" />
                  </DataGrid>
                </>
              ) : displayAllRouteTasks ? (
                <>
                  <DataGrid
                    identity="grdRoutesMgmtAllTasks"
                    reference={this.refGridAllTasks}
                    dataSource={allRouteTasksDS || []}
                    showBorders={false}
                    groupPanelVisible={true}
                    columnAutoWidth={true}
                    columns={gridAllRouteTasks()}
                    onToolbarPreparing={(e) =>
                      gridAllRouteToolbarPreparing(
                        e,
                        this.backFromAllRoutesTasks,
                        this.handlerExportToPDF,
                        this.handlerExportToExcel,
                        "AllRoute-Tasks"
                      )
                    }
                  >
                    <GroupPanel visible={true} />
                    <Grouping autoExpandAll={true} contextMenuEnabled={false} />
                    <Paging enabled={true} pageSize={30} />
                    <Pager
                      showPageSizeSelector={false}
                      showNavigationButtons={false}
                      showInfo={true}
                      visible={true}
                    />
                    <Export fileName="gvView" />
                  </DataGrid>
                </>
              ) : displayAllRouteTeams ? (
                <>
                  {" "}
                  <DataGrid
                    identity="grdRoutesMgmtAllTeams"
                    reference={this.refGridAllTeams}
                    dataSource={allRouteTeamsDS || []}
                    showBorders={false}
                    groupPanelVisible={true}
                    columnAutoWidth={true}
                    columns={gridAllRouteTeams()}
                    onToolbarPreparing={(e) =>
                      gridAllRouteToolbarPreparing(
                        e,
                        this.backFromAllRoutesTeams,
                        this.handlerExportToPDF,
                        this.handlerExportToExcel,
                        "AllRoute-Teams"
                      )
                    }
                  >
                    <GroupPanel visible={true} />
                    <Grouping autoExpandAll={true} contextMenuEnabled={false} />
                    <Paging enabled={true} pageSize={30} />
                    <Pager
                      showPageSizeSelector={false}
                      showNavigationButtons={false}
                      showInfo={true}
                      visible={true}
                    />
                    <Export fileName="gvView" />
                  </DataGrid>
                </>
              ) : (
                <></>
              )}
            </div>

            {/* STEP 2 */}
            <div
              className={styles.step}
              style={{
                height:
                  document.getElementById("cdrRoutesMgmt")?.offsetHeight -
                  170 +
                  "px",
              }}
            >
              <div className={styles.headerRoute}>
                <div className={styles.routeDescription}>
                  <form>
                    <Form
                      formData={this.state}
                      labelLocation="left"
                      showColonAfterLabel={true}
                      colCount={2}
                      onFieldDataChanged={() => {
                        this.setState(
                          {
                            stepWasUpdated: true,
                            step2RouteDescUpdate: true,
                          },
                          () => localStorage.setItem("hasUpdates", "true")
                        );
                      }}
                    >
                      <SimpleItem
                        dataField="routeDescSelected"
                        editorType="dxTextBox"
                        isRequired={true}
                        cssClass="txtRouteDescription"
                        editorOptions={{ maxLength: 150 }}
                      >
                        <RequiredRule
                          message={t("Route Description is required")}
                        />
                        <Label text={t("Route Description")} />
                      </SimpleItem>

                      <SimpleItem>
                        <CheckBox
                          id="chkActivityViewer"
                          tag="showActivityValue"
                          value={showActivityValue}
                          onValueChanged={this.onActivityViewerValueChanged}
                          text={t("Show in Activity Viewer?")}
                        />
                      </SimpleItem>
                    </Form>
                  </form>
                </div>
                <div className={styles.butttonCommand}></div>
              </div>
              <br />
              <Accordion
                id="acdRoutesMgmt"
                ref={this.refAccordion}
                collapsible={false}
                multiple={false}
              >
                <Item visible={false}></Item>
                <Item className={styles.container}>
                  <div
                    className={styles.tasksContainer}
                    style={{ height: containersHeight }}
                  >
                    <div className={styles.taskContainerTreeList}>
                      <TreeList
                        id="trlRouteTasks"
                        reference={this.refTreeList}
                        columns={["ItemDesc"]}
                        dataSource={treeListData}
                        itemsExpr="Id"
                        keyExpr="Id"
                        parentIdExpr="ParentId"
                        defaultSelectedRowKeys={selectedRowKeys}
                        defaultExpandedRowKeys={expandedRowKeys}
                        onSelectionChanged={this.onSelectionChangedHanlder}
                        onRowExpanding={this.onTreeListItemClick}
                      >
                        <TreeListSelection
                          recursive={true}
                          mode={
                            [4, 3].includes(globalAccessLevel)
                              ? "multiple"
                              : "none"
                          }
                        />
                      </TreeList>
                    </div>

                    <div className={styles.taskContainerDataGrid}>
                      <DataGrid
                        identity="grdRoutesMgmtTasks"
                        keyExpr="ItemId"
                        reference={this.refGridTasks}
                        dataSource={tasksDS || []}
                        showBorders={false}
                        scrollingMode={scrollingMode}
                        columnResizingMode="nextColumn"
                        columnAutoWidth={true}
                        columns={gridTasksColumns(t)}
                        onRowPrepared={this.onRowPrepared}
                        onCellClick={this.handlerTaskStep2CellClick}
                        rowDragging={{
                          allowReordering: true,
                          dragDirection: "vertical",
                          dropFeedbackMode: "push",
                          onDragEnd: () => {
                            this.setState({
                              stepWasUpdated: true,
                              step2_WasUpdated: true,
                            });
                            localStorage.setItem("hasUpdates", "true");
                          },
                          onReorder: function (e) {
                            var visibleRows = e.component.getVisibleRows(),
                              toIndex = tasksDS.indexOf(
                                visibleRows[e.toIndex].data
                              ),
                              fromIndex = tasksDS.indexOf(e.itemData);

                            tasksDS.splice(fromIndex, 1);
                            tasksDS.splice(toIndex, 0, e.itemData);

                            e.component.refresh();
                          },
                        }}
                        defaultSelectedRowKeys={treeListData
                          .filter((f) => f.Selected)
                          .map((m) => m.ItemId)}
                        onToolbarPreparing={(e) =>
                          gridTasksToolbarPreparing(
                            e,
                            t,
                            this.changeRowsForPageTasks,
                            this.handlerExportToPDF,
                            this.handlerExportToExcel
                          )
                        }
                      >
                        <Pager
                          showPageSizeSelector={false}
                          showNavigationButtons={true}
                          allowedPageSizes={[5, 10, 20, 30, 40, 50]}
                        />
                        <Paging defaultPageSize={30} />
                        <RowDragging
                          allowReordering={true}
                          onReorder={this.onReorder}
                          showDragIcons={true}
                        />
                        <Template
                          name="totalRowsPerPage"
                          render={this.toolbarItemRender}
                        />
                        <Editing
                          mode="row"
                          useIcons={true}
                          allowUpdating={false}
                          allowAdding={false}
                        />
                        <Selection
                          mode="multiple"
                          showCheckBoxesMode="always"
                          allowSelectAll={true}
                        />
                        <Export fileName="gvView" />
                        <FilterRow visible={false} />
                        <Sorting mode="none" />
                      </DataGrid>
                    </div>
                  </div>
                </Item>
              </Accordion>
            </div>

            {/* STEP 3 */}
            <div
              className={styles.step}
              style={{
                height:
                  document.getElementById("cdrRoutesMgmt")?.offsetHeight -
                  170 +
                  "px",
              }}
            >
              <div className={styles.headerRoute}>
                <div className={styles.routeDescription}>
                  <span>
                    {document.querySelector("[name=routeDescSelected]")?.value}
                  </span>
                  <Button
                    id="btnAddTourStop"
                    hint={t("Add Tour Stop")}
                    text={t("Add Tour Stop")}
                    primary
                    style={{ height: "30px", width: "200px" }}
                    onClick={() => {
                      this.handlerAddTourStop();
                    }}
                  />
                  <div style={{ display: "none" }}>
                    <span style={{ fontSize: "small" }}>Tour Map</span>
                    <input
                      type="text"
                      id="tourMap"
                      style={{ marginLeft: "10px", fontSize: "small" }}
                    ></input>
                  </div>
                </div>

                <div className={styles.butttonCommand}></div>
              </div>
              <div
                className={styles.tasksContainer}
                style={{ height: containersHeight }}
              >
                <div style={{ width: "30%", margin: "5px" }}>
                  <DataGrid
                    identity="grdTourStop"
                    keyExpr="TourId"
                    reference={this.refGridTourStopsListAdded}
                    dataSource={tourStopsList}
                    showBorders={false}
                    rowAlternationEnabled={false}
                    allowFiltering={false}
                    headerFilter={{ visible: false }}
                    onRowInserting={this.onAddTourStop.bind(this)}
                    onEditorPreparing={(e) => {
                      if (
                        e.parentType === "dataRow" &&
                        e.dataField === "TourDesc"
                      ) {
                        e.editorOptions.maxLength = 50;
                      }
                    }}
                    onSelectionChanged={this.handleSelectTourStop}
                    columns={tourStopsListColumns}
                    filterRow={false}
                    rowDragging={{
                      allowReordering: true,
                      dragDirection: "vertical",
                      dropFeedbackMode: "push",
                      onDragEnd: () => this.step3_WasUpdated(true),
                      onReorder: function (e) {
                        var visibleRows = e.component.getVisibleRows(),
                          toIndex = tourStopsList.indexOf(
                            visibleRows[e.toIndex].data
                          ),
                          fromIndex = tourStopsList.indexOf(e.itemData);

                        tourStopsList.splice(fromIndex, 1);
                        tourStopsList.splice(toIndex, 0, e.itemData);

                        e.component.refresh();
                      },
                    }}
                    onRowUpdating={this.handleUpdateTourStopDesc}
                    allowColumnResizing={false}
                  >
                    <Editing
                      mode="row"
                      useIcons={true}
                      allowUpdating={true}
                      allowAdding={false}
                      allowSearch={false}
                    />
                    <Column
                      dataField={"TourDesc"}
                      caption={t("Tour Stops")}
                      allowSearch={false}
                      allowSorting={false}
                      validationRules={[{ type: "required" }]}
                      width="150px"
                    />
                    <Column
                      type="buttons"
                      buttons={[
                        {
                          name: "edit",
                          icon: getIcon(icons.gridEdit),
                          hint: "Edit",
                          cssClass: iconStyle.icon,
                        },
                        {
                          name: "remove",
                          icon: getIcon(icons.remove),
                          hint: "Remove",
                          onClick: this.handleSelectTourStopRemoving,
                          cssClass: iconStyle.icon,
                        },
                        {
                          name: "map",
                          icon: getIcon(icons.map),
                          hint: "Tour Map Image",
                          cssClass: iconStyle.icon,
                          onClick: (e) => {
                            document.getElementById("tourMap").value =
                              e.row.data.TourMap || "";
                            this.setState({
                              tourStopSelected: e.row.data,
                              showSavePopup: true,
                            });
                          },
                        },
                      ]}
                      cssClass={styles.btnGridButtons}
                      width="90px"
                      allowSearch={false}
                    />

                    <Selection mode="multiple" showCheckBoxesMode="none" />
                    <RowDragging
                      allowReordering={true}
                      onReorder={this.onReorder}
                      showDragIcons={true}
                    />
                  </DataGrid>
                </div>

                <div
                  className={styles.taskContainerDataGrid}
                  style={{ marginTop: "-60px", width: "70%" }}
                >
                  <br />
                  <DataGrid
                    identity="grdRoutesMgmtTasks"
                    keyExpr="ItemId"
                    reference={this.refGridTourStops}
                    dataSource={tourStopTasks}
                    showBorders={false}
                    scrollingMode={scrollingMode}
                    columnResizingMode="nextColumn"
                    columnAutoWidth={true}
                    columns={columnsTaskGrid_Step3}
                    onRowPrepared={this.onRowPrepared}
                    onSelectionChanged={this.handleSelectTasks_TS}
                    onCellClick={this.onTasksCellClick}
                    onEditorPreparing={this.onEditorPreparing_TS_Tasks}
                    rowDragging={{
                      allowReordering: true,
                      dragDirection: "vertical",
                      dropFeedbackMode: "push",
                      onDragEnd: (e) => {
                        if (
                          !this.refGridTourStopsListAdded.current?.instance?.getSelectedRowKeys()
                            .length
                        ) {
                          warning(t("Please, select at least one tour stop"));
                          return;
                        }

                        this.setState({
                          stepWasUpdated: true,
                          step3_WasUpdated: true,
                        });
                        localStorage.setItem("hasUpdates", "true");
                        e.component.refresh();
                      },
                      onReorder: function (e) {
                        let data = tourStopTasks;
                        var visibleRows = e.component.getVisibleRows(),
                          toIndex = data.indexOf(visibleRows[e.toIndex].data),
                          fromIndex = data.indexOf(e.itemData);
                        data.splice(fromIndex, 1);
                        data.splice(toIndex, 0, e.itemData);

                        e.component.refresh();
                      },
                    }}
                  >
                    <Pager
                      showPageSizeSelector={false}
                      showNavigationButtons={true}
                      allowedPageSizes={[5, 10, 20, 30, 40, 50]}
                    />
                    <Paging defaultPageSize={30} />
                    <Template
                      name="totalRowsPerPage"
                      render={this.toolbarItemRender}
                    />
                    <GroupPanel visible={true} />
                    <Grouping autoExpandAll={true} contextMenuEnabled={false} />
                    <Selection
                      mode="multiple"
                      showCheckBoxesMode="always"
                      allowSelectAll={true}
                    />
                    <Sorting mode="multiple" />
                  </DataGrid>
                </div>
              </div>
            </div>

            {/* STEP 4 */}
            <div
              className={styles.step}
              style={{
                height:
                  document.getElementById("cdrRoutesMgmt")?.offsetHeight -
                  170 +
                  "px",
              }}
            >
              <div
                className={styles.butttonCommand}
                style={{ float: "right" }}
              ></div>
              <div
                className={styles.teamsContainer}
                style={{ height: containersHeight, marginTop: "48px" }}
              >
                <DataGrid
                  identity="grdRoutesMgmtTeams"
                  reference={this.refGridTeams}
                  dataSource={
                    [4, 3].includes(globalAccessLevel)
                      ? teamsDS
                      : teamsDS.filter((team) => team.Selected)
                  }
                  keyExpr="TeamId"
                  showBorders={false}
                  onContentReady={this.setIdsRouteTeamsGridComponents}
                  defaultSelectedRowKeys={teamsDS
                    ?.filter((f) => f.Selected)
                    .map((m) => m.TeamId)}
                  onToolbarPreparing={(e) =>
                    gridTeamsToolbarPreparing(
                      t,
                      e,
                      this.handlerExportToExcel,
                      this.handlerExportToPDF
                    )
                  }
                  columns={gridTeamsColumns()}
                  onCellClick={(e) => {
                    if (e.text === "") {
                      localStorage.setItem("hasUpdates", "true");
                      this.setState({
                        stepWasUpdated: true,
                        step4_WasUpdated: true,
                      });
                    }
                  }}
                >
                  {[4, 3].includes(globalAccessLevel) && (
                    <Selection
                      mode="multiple"
                      showCheckBoxesMode="always"
                      width="80px"
                    />
                  )}
                  <Export fileName="gvView" />
                </DataGrid>
              </div>
            </div>
          </MyStepper>
        </div>

        {showSavePopup && (
          <Save
            t={t}
            tourStopSelected={tourStopSelected}
            routeIdSelected={routeSelected.RouteId}
            onClose={() => this.setState({ showSavePopup: false })}
            handleStep3={() => this.handleStep3()}
            onSave={() => {
              let TourStop = {
                tourId: tourStopsList.find(
                  (x) => x.TourDesc === tourStopSelected
                ).TourId,
                tourMap: document.getElementById("tourMap").value,
              };
              updateTourMapLink(TourStop).then(() => {
                this.setState({ showSavePopup: false }, () => {
                  this.handleStep3();
                });
              });
            }}
          />
        )}
      </Card>
    );
  }
}

export default RoutesManagement;
