import React, { PureComponent } from "react";
import {
  Column,
  Editing,
  Selection,
  Pager,
  Paging,
  Export,
  FilterRow,
  Sorting,
} from "devextreme-react/ui/data-grid";
import Form, {
  SimpleItem,
  Label,
  RequiredRule,
} from "devextreme-react/ui/form";
import { Accordion, Item } from "devextreme-react/ui/accordion";
import { Selection as TreeListSelection } from "devextreme-react/ui/tree-list";
import { Template } from "devextreme-react/core/template";
import TreeList from "../../../../components/TreeList";
import DataGrid from "../../../../components/DataGrid";
import Button from "../../../../components/Button";
import Card from "../../../../components/Card";
import { displayPreload } from "../../../../components/Framework/Preload";
import { getUserRole } from "../../../../services/auth";
import { warning, error } from "../../../../services/notification";
import { confirm } from "devextreme/ui/dialog";
import {
  getTeams,
  getTeamRoutes,
  getReportTeamTasks,
  getTeamTasks,
  getTeamUsers,
  getReportAllTeamRoutes,
  getReportAllTeamUsers,
  getReportAllTeamTasks,
  addTeam,
  updateTeam,
  deleteTeams,
  updataTeamRoutesAssociations,
  updataTeamTasksAssociations,
  updataTeamUsersAssociations,
} from "../../../../services/teams";
import { getLines } from "../../../../services/plantModel";
import {
  generateExportDocument,
  getIcon,
  getKeySorted,
  setIdsByClassName,
} from "../../../../utils";
import {
  gridTeamsToolbarPreparing,
  gridTeamsColumns,
  gridRoutesToolbarPreparing,
  gridRoutesColumns,
  gridTasksToolbarPreparing,
  gridTasksColumns,
  gridUsersToolbarPreparing,
  gridUsersColumns,
  gridAllReportsToolbarPreparing,
  gridAllTeamRoutesColumns,
  gridAllTeamUsersColumns,
  gridAllTeamTasksColumns,
} from "./options";
import {
  buildTreeListLines,
  buildTreeListItems,
  treeListTasksSelected,
  treeListExpandedKeys,
  uniqueItemId,
} from "../shared";
import icons from "../../../../resources/icons";
import styles from "./styles.module.scss";
// import DataSource from "devextreme/data/data_source";

class TeamsManagement extends PureComponent {
  constructor(props) {
    super(props);

    this.refGridTeams = React.createRef();
    this.refAccordion = React.createRef();
    this.refGridRoutes = React.createRef();
    this.refGridTasks = React.createRef();
    this.refGridUsers = React.createRef();
    this.refTreeList = React.createRef();
    this.refGridAllRoutes = React.createRef();
    this.refGridAllUsers = React.createRef();
    this.refGridAllTasks = React.createRef();

    this.toolbarItemRender = this.toolbarItemRender.bind(this);

    this.state = {
      teamsDS: [],
      routesDS: [],
      tasksDS: [],
      usersDS: [],
      linesDS: [],
      allTeamRoutesDS: [],
      allTeamUsersDS: [],
      allTeamTasksDS: [],
      displayTeamScreen: false,
      displayAllTeamRoutes: false,
      displayAllTeamUsers: false,
      displayAllTeamTasks: false,
      teamSelected: {},
      teamDescSelected: "",
      userSelected: {},
      treeListData: [],
      treeListSelectedItems: [],
      selectedRowKeys: [],
      expandedRowKeys: [],
      scrollingMode: "",
      openTreeList: true,
      selectBoxVisible: false,
      linesLoaded: [],
      tasksLoaded: [],
      containersHeight: "",
    };
  }

  componentDidMount() {
    this.reloadTeams();
    this.lines();
  }

  componentDidUpdate = () => {
    this.setIdsButtonsGridTeams();
  };

  setIdsButtonsGridTeams = () => {
    setIdsByClassName([
      "btnAddTeam",
      "btnDeleteTeam",
      "btnAllTeamRoutes",
      "btnAllTeamUsers",
      "btnAllTeamTasks",
      "btnExcelExportTeamsMgmt",
      "btnPdfExportTeamsMgmt",
      // All Teams
      "btnReturnToTeamsMgmt",
      "btnAllTeamExcelExport",
      "btnAllTeamPDFExport",
    ]);
  };

  setIdsGrdTeams = () => {
    setIdsByClassName([
      // Main Grid
      // Input Search
      {
        idContainer: "grdTeamsMgmt",
        class: "dx-texteditor-input",
        ids: ["txtGrdTeamsMgmt"],
        same: true,
      },
      // Buttons Save and cancel (edit route)
      {
        idContainer: "grdTeamsMgmt",
        class: "dx-link dx-link-icon",
        ids: ["lnkGrdTeamsMgmt"],
        same: true,
      },
      // Grid Edit button
      {
        idContainer: "grdTeamsMgmt",
        class: "dx-link-edit",
        ids: ["btnEditGrdTeamsMgmt"],
        same: true,
      },
    ]);
  };

  setIdsTeamUsersGridComponents = () => {
    setIdsByClassName([
      "txtTeamDescription",
      "btnExcelExportTeamsMgmtUsers",
      "btnPDFExportTeamsMgmtUsers",
      // Accordion items
      {
        idContainer: "acdTeamsMgmt",
        class: "dx-item dx-accordion-item",
        ids: ["acdItemTeams"],
        same: true,
      },
    ]);
  };

  setIdsTeamRoutesGridComponents = () => {
    setIdsByClassName([
      "btnExcelExportTeamsMgmtRoutes",
      "btnPDFExportTeamsMgmtRoutes",
      // Input Search
      {
        idContainer: "grdTeamsMgmtRoutes",
        class: "dx-texteditor-input",
        ids: ["txtColumnSearchGrdTeamRoutes"],
        same: true,
      },
      // Grid Checkboxes
      {
        idContainer: "grdTeamsMgmtRoutes",
        class: "dx-checkbox-container",
        ids: ["chkGrdTeamRoutes"],
        same: true,
      },
    ]);
  };

  setIdsTeamTasksGridAndTreeList = () => {
    setTimeout(() => {
      setIdsByClassName([
        // TreeList checkbox
        {
          idContainer: "trlTeamTasks",
          class: "dx-checkbox-container",
          ids: ["chkTeamTreeListItem"],
          same: true,
        },
      ]);
    }, 1000);
  };

  setIdsTeamTasksGridComponents = () => {
    setIdsByClassName([
      "sboRowsPerPageTeamsMgmt",
      "btnExcelExportTeamsMgmtTasks",
      "btnPDFExportTeamsMgmtTasks",
    ]);
    this.setIdsTeamTasksGridAndTreeList();
  };

  setIdsAllTeamTasks = () => {
    setTimeout(() => {
      setIdsByClassName([
        {
          idContainer: "grdTeamsMgmtAllTasks",
          class: "dx-texteditor-input",
          ids: ["txtGrdAllTeamTasks"],
          same: true,
        },
      ]);
    }, 1000);
  };

  reloadTeams = () => {
    displayPreload(true);
    getTeams().then((response) => {
      this.setState(
        {
          teamsDS: response,
          linesLoaded: [],
          selectedRowKeys: [],
          expandedRowKeys: [],
          scrollingMode: window.innerWidth > 992 ? "standard" : "virtual",
        },
        () => {
          displayPreload(false);
          if (this.state.displayTeamScreen) {
            this.refGridTeams.current.instance.refresh();
            this.backToTeamsView();
          }
        }
      );
    });
  };

  teams = (teamId) => {
    return new Promise((resolve) =>
      resolve(
        getTeamRoutes(teamId).then((response) => {
          this.setState({
            teamsDS: response,
          });
        })
      )
    );
  };

  routes = (teamId) => {
    return new Promise((resolve) =>
      resolve(
        getTeamRoutes(teamId).then((response) => {
          this.setState({
            routesDS: response,
          });
        })
      )
    );
  };

  tasks = (routId) => {
    return new Promise((resolve) =>
      resolve(
        getReportTeamTasks(routId).then((response) => {
          if (response === undefined) return;
          this.setState({
            tasksDS: response,
            linesLoaded: [],
            tasksLoaded: [...response],
          });
        })
      )
    );
  };

  users = (teamId) => {
    return new Promise((resolve) =>
      resolve(
        getTeamUsers(teamId).then((response) => {
          this.setState({
            usersDS: response,
          });
        })
      )
    );
  };

  lines = () => {
    return new Promise((resolve) =>
      resolve(
        getLines().then((response) => {
          this.setState({
            linesDS: response,
          });
        })
      )
    );
  };

  handlerTeamScreen = (e) => {
    let data = e.row.data;

    displayPreload(true);
    Promise.all([
      this.routes(data.TeamId),
      this.users(data.TeamId),
      this.tasks(data.TeamId),
      this.treeListData(data.TeamId),
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

      // This line is to solve temporary the issue 1081 from Panaya
      // Error while updating some of the existing Routes
      tasksDS = tasksDS.filter((task) => task.ItemId !== -1);

      // Eliminate repited Ids from BBDD, only for BELLEVILLE RPT server.
      tasksDS = uniqueItemId(tasksDS || []);

      this.setState(
        {
          displayTeamScreen: true,
          teamDescSelected: data.TeamDescription,
          teamSelected: data,
          tasksDS,
        },
        () => {
          this.refAccordion.current.instance.expandItem(0);
          let refTreeList = this.refTreeList?.current;
          if (refTreeList !== null) refTreeList.instance.refresh();
          displayPreload(false);
          setTimeout(() => {
            let containersHeight =
              document.getElementById("container").offsetHeight;
            this.setState({
              containersHeight: containersHeight - 120 + "px",
            });
            if (this.refTreeList.current !== null) {
              this.refTreeList.current.instance.repaint();
              this.refTreeList.current.instance.refresh();
            }
            this.setIdsTeamUsersGridComponents();
            this.setIdsTeamTasksGridAndTreeList();
          }, 250);
        }
      );
    });
  };

  handlerAddTeam = () => {
    let grid = this.refGridTeams.current.instance;
    grid.addRow();
  };

  handlerDeleteTeam = () => {
    const { t } = this.props;
    let grid = this.refGridTeams.current.instance;
    let data = grid.getSelectedRowsData();

    if (data.length === 0) {
      warning(t("Please, select at least one Team"));
      return;
    }

    let dialog = confirm(
      `<span>You are about to delete ${data.length} team/s. Are you sure?</span>`,
      t("Delete Team/s")
    );
    dialog.then((dialogResult) => {
      if (dialogResult) {
        displayPreload(true);
        deleteTeams(data.map((m) => m.TeamId).join(",")).then(() =>
          this.reloadTeams()
        );
      }
    });
  };

  treeListData = (teamId) => {
    return new Promise((resolve) =>
      resolve(
        getTeamTasks(teamId).then((response) => {
          displayPreload(true);
          if (response.length !== 0) {
            // Eliminate repited Ids from BBDD, only for BELLEVILLE RPT server.
            response = uniqueItemId(response || []);

            let selectedRowsIds = response
              .filter((f) => f.Selected)
              .map((m) => m.Id);
            let expandedRowKeys = treeListExpandedKeys(
              response,
              selectedRowsIds
            );

            response.length !== 0 &&
              response.forEach((x) => {
                if (x.Level === 1) x.ParentId = 0;
              });

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
                buildTreeListLines(this.state).then(
                  (resp) => {
                    this.setState({ treeListData: resp });
                  },
                  () => {
                    this.refTreeList.current.instance.refresh();
                    this.setIdsTeamTasksGridAndTreeList();
                    displayPreload(false);
                  }
                );
              }
            );
          } else {
            buildTreeListLines(this.state).then(
              (resp) => {
                this.setState({
                  treeListData: resp,
                });
              },
              () => {
                this.refTreeList.current.instance.refresh();
                this.refAccordion.current.instance.expandItem(0);
                this.setIdsTeamTasksGridAndTreeList();
                displayPreload(false);
              }
            );
          }
        })
      )
    );
  };

  sectionsUpdate = () => {
    let currentDesc = this.state.teamSelected.TeamDescription;
    var updateDesc = document.querySelector("[name=teamDescSelected]").value;
    let isTeamDescUpdate = currentDesc !== updateDesc;
    let keyRoute = "RouteId";
    let route1 = this.state.routesDS.filter((f) => f.Selected);
    let route2 = this.refGridRoutes.current?.instance.getSelectedRowsData();
    let isRoutesUpdate =
      route2 !== undefined &&
      getKeySorted(route1, keyRoute) !== getKeySorted(route2, keyRoute);
    let keyUser = "UserId";
    let user1 = this.state.usersDS.filter((f) => f.Selected);
    let user2 =
      this.refGridUsers.current?.instance.getSelectedRowsData() || user1;
    let isUserUpdate =
      getKeySorted(user1, keyUser) !== getKeySorted(user2, keyUser);

    let task1 = this.refGridTasks.current?.instance.getSelectedRowsData();
    task1 = task1 === undefined ? this.state.tasksLoaded : task1;

    // This line is to solve temporary the issue 1081 from Panaya
    // Error while updating some of the existing Routes
    let task2 = this.state.tasksLoaded.filter((task) => task.ItemId !== -1);

    let isTasksUpdate = JSON.stringify(task1) !== JSON.stringify(task2);

    return {
      isTeamDescUpdate,
      isRoutesUpdate,
      isTasksUpdate,
      isUserUpdate,
    };
  };

  teamDescriptionIsEmpty = () => {
    return document.querySelector("[name=teamDescSelected]").value === "";
  };

  handlerBackToTeams = () => {
    const { t } = this.props;
    const globalAccessLevel = getUserRole();
    if (![4, 3].includes(globalAccessLevel)) this.backToTeamsView();
    setTimeout(() => {
      var { isTeamDescUpdate, isRoutesUpdate, isTasksUpdate, isUserUpdate } =
        this.sectionsUpdate();

      if (isTeamDescUpdate || isRoutesUpdate || isTasksUpdate || isUserUpdate) {
        let dialog = confirm(
          `<span>` +
            t("Do you have changes without save, do you want save it?") +
            `</span>`,
          t("Unsaved changes")
        );
        dialog.then((dialogResult) => {
          if (dialogResult) {
            this.onUpdateTeam(this.state.teamSelected);
          } else this.backToTeamsView();
        });
      } else this.backToTeamsView();
    }, 500);
  };

  handlerAllTeamRoutes = () => {
    displayPreload(true);
    getReportAllTeamRoutes().then((response) =>
      this.setState(
        {
          displayAllTeamRoutes: true,
          allTeamRoutesDS: response,
        },
        () => {
          displayPreload(false);
        }
      )
    );
  };

  handlerAllTeamUsers = () => {
    displayPreload(true);
    getReportAllTeamUsers().then((response) =>
      this.setState(
        {
          displayAllTeamUsers: true,
          allTeamUsersDS: response,
        },
        () => {
          displayPreload(false);
        }
      )
    );
  };

  handlerAllTeamTasks = () => {
    displayPreload(true);
    getReportAllTeamTasks().then((response) =>
      this.setState(
        {
          displayAllTeamTasks: true,
          allTeamTasksDS: response,
        },
        () => {
          displayPreload(false);
          this.setIdsAllTeamTasks();
        }
      )
    );
  };

  handlerExportToPDF = async (view) => {
    let fileName = view === "Teams" ? "gvSummary.pdf" : "gvView.pdf";

    let ref =
      view === "Teams"
        ? this.refGridTeams
        : view === "Routes"
        ? this.refGridRoutes
        : view === "Tasks"
        ? this.refGridTasks
        : view === "Users"
        ? this.refGridUsers
        : view === "AllTeamRoutes"
        ? this.refGridAllRoutes
        : view === "AllTeamUsers"
        ? this.refGridAllUsers
        : this.refGridAllTasks;

    let columns = Array(
      ref.current.instance
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

    let instance = ref.current.instance;
    let data = [];
    if (
      view === "AllTeamRoutes" ||
      view === "AllTeamUsers" ||
      view === "AllTeamTasks"
    )
      data = instance.getDataSource().store()._array;
    else if (view === "Teams")
      data = instance.getCombinedFilter()
        ? instance.getDataSource()._items
        : instance.getDataSource().store()._array;
    else data = instance.getSelectedRowsData();

    // let data = await new DataSource({
    //   store: [...ref.current.instance.getDataSource().store()._array],
    //   filter: ref.current.instance.getCombinedFilter(),
    //   sort: ref.current.instance.getDataSource().sort(),
    //   paginate: false,
    // }).load();

    this.exportToPDF(columns, data, fileName);
  };

  handlerExportToExcel = (view) => {
    let ref =
      view === "Teams"
        ? this.refGridTeams
        : view === "Routes"
        ? this.refGridRoutes
        : view === "Tasks"
        ? this.refGridTasks
        : view === "Users"
        ? this.refGridUsers
        : view === "AllTeamRoutes"
        ? this.refGridAllRoutes
        : view === "AllTeamUsers"
        ? this.refGridAllUsers
        : this.refGridAllTasks;

    ref.current.instance.exportToExcel(
      view === "Routes" || view === "Tasks" || view === "Users" ? true : false
    );
  };

  exportToPDF = (columns, data, fileName) => {
    var doc = generateExportDocument(columns, data);
    doc.save(fileName);
  };

  onAddTeam(e) {
    let teamsDS = this.state.teamsDS;
    displayPreload(true);
    if (e.data.TeamDescription !== undefined) {
      if (teamsDS?.filter((team) => team.TeamDescription.toLowerCase() === e.data.TeamDescription.toLowerCase()).length === 0) { //Check that team description doesn't already exist
        addTeam({
          TeamDesc: e.data.TeamDescription,
        }).then(() => {
          this.reloadTeams();
        });
      } else {
        this.reloadTeams();
        error(this.props.t("This team description already exists"));
      }
    } else {
      warning("You must enter a description");
    }
  }

  onUpdateTeam(team) {
    if (this.teamDescriptionIsEmpty()) return;
    var cantTemp = 1;
    var cantSectionsUpdates = Object.values(this.sectionsUpdate()).filter(
      (x) => x
    ).length;
    setTimeout(() => {
      let teamId = this.state.teamSelected.TeamId;
      var { isTeamDescUpdate, isRoutesUpdate, isTasksUpdate, isUserUpdate } =
        this.sectionsUpdate();

      if (isTeamDescUpdate || isRoutesUpdate || isTasksUpdate || isUserUpdate) {
        displayPreload(true);

        // ## handlerTeamDescription
        if (isTeamDescUpdate) {
          let teamDesc = document.querySelector("[name=teamDescSelected]").value
          let teamsDS = this.state.teamsDS;
          if (teamsDS?.filter((team) => team.TeamDescription.toLowerCase() === teamDesc.toLowerCase()).length === 0) { //Check that team description doesn't already exist
            setTimeout(() => {
              let updatedTeam = {
                TeamId: team.TeamId,
                TeamDesc: teamDesc,
                NbrRoutes: team.NbrRoutes,
                NbrTasks: team.NbrTasks,
                NbrUsers: team.NbrUsers,
              };
              updateTeam(updatedTeam).then(() => {
                if (cantTemp === cantSectionsUpdates) {
                  displayPreload(false);
                  this.reloadTeams();
                }
                cantTemp++;
              });
            }, 250);
         } else {
          //Handle team description already existing
          error(this.props.t("This team description already exists"));
          displayPreload(false);
          return; //Don't update the rest of the team
         }
        }
        // ## handlerSaveTeamRoutesAssociations
        if (isRoutesUpdate) {
          setTimeout(() => {
            let routesDSItemsIds =
              this.refGridRoutes.current.instance.getSelectedRowsData();
            updataTeamRoutesAssociations({
              TeamId: teamId,
              IdList: routesDSItemsIds.map((m) => m.RouteId).join(","),
            }).then(() => {
              if (cantTemp === cantSectionsUpdates) {
                displayPreload(false);
                this.reloadTeams();
              }
              cantTemp++;
            });
          }, 500);
        }
        // ## handlerSaveTeamTasksAssociations
        if (isTasksUpdate) {
          if (this.refGridTasks.current === null) {
            this.refAccordion.current.instance.expandItem(2);
          }
          setTimeout(() => {
            let tasksDSItemsIds = this.refGridTasks.current.instance
              .getSelectedRowKeys()
              .join(",");

            if (tasksDSItemsIds.length >= 0) {
              updataTeamTasksAssociations({
                TeamId: teamId,
                IdList: tasksDSItemsIds,
              }).then((response) => {
                if (cantTemp === cantSectionsUpdates) {
                  displayPreload(false);
                  this.reloadTeams();
                }
                cantTemp++;
              });
            }
          }, 750);
        }

        // ## handlerSaveTeamUserAssociations
        if (isUserUpdate) {
          setTimeout(() => {
            let data = this.refGridUsers.current.instance.getSelectedRowsData();
            displayPreload(true);
            updataTeamUsersAssociations({
              TeamId: teamId,
              IdList: data.map((m) => m.UserId).join(","),
            }).then(() => {
              if (cantTemp === cantSectionsUpdates) {
                displayPreload(false);
                this.reloadTeams();
              }
              cantTemp++;
            });
          }, 1000);
        }
      }
    }, 500);
  }

  changeRowsForPageTasks = (e) => {
    let refGridTasks = this.refGridTasks.current.instance;
    refGridTasks.option("paging.pageSize", e.value);
  };

  toolbarItemRender() {
    const { t } = this.props;
    return (
      <div className="informer">
        <span className="name">{t("Number of Rows per page")}: </span>
      </div>
    );
  }

  onShowHideTreeList = () => {
    this.setState({
      openTreeList: !this.state.openTreeList,
    });
  };

  onTreeListItemClick = (e) => {
    // var temp = e.component
    //   .getDataSource()
    //   .items()
    //   .find((f) => f.key === e.key);

    var temp = e.component
      .getDataSource()
      ._store._array.find((f) => f.Id === e.key);

    if (temp !== undefined) {
      // let item = temp.data === undefined ? e : temp.data;
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
              this.refTreeList.current.instance.refresh();
              this.refGridTasks.current.instance.refresh();
              this.setIdsTeamTasksGridAndTreeList();
              displayPreload(false);
            }
          );
        });
      }
    }
  };

  onSelectionChangedHanlder = (e) => {
    let elem = [];
    var tasksDStemp = this.state.tasksDS;
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
              this.refTreeList.current.instance.refresh();
              this.refGridTasks.current.instance.refresh();

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
                    ItemId: item.ItemId,
                  });
                }
              });

              this.setState({ tasksDS: tasksDStemp }, () => {
                displayPreload(false);
                this.setIdsTeamTasksGridAndTreeList();
              });
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
              ItemId: item.ItemId,
            });
          }
        });
        displayPreload(false);
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
        this.setIdsTeamTasksGridAndTreeList();
        displayPreload(false);
      }
    }

    this.refGridTasks.current.instance.refresh();
  };

  backToTeamsView = () => {
    let refAccordion = this.refAccordion.current.instance;
    let refTreeList = this.refTreeList.current?.instance;

    if (this.state.tasksLoaded.length === 0) {
      if (refTreeList !== undefined) {
        this.state.treeListData.forEach((t) => {
          if (refTreeList.isRowExpanded(t.Id)) refTreeList.collapseRow(t.Id);
        });
        refTreeList.deselectAll();
      }
    }

    this.setState(
      {
        routesDS: [],
        tasksDS: [],
        usersDS: [],
        treeListData: [],
        expandedRowKeys: [],
        selectedRowKeys: [],
        displayTeamScreen: false,
        displayAllTeamRoutes: false,
        displayAllTeamUsers: false,
        displayAllTeamTasks: false,
      },
      () => {
        refAccordion.collapseItem(1);
        refAccordion.collapseItem(2);
        refAccordion.collapseItem(3);
      }
    );
  };

  backFromAllTeamRoutes = () => {
    this.setState({
      displayAllTeamRoutes: false,
    });
  };

  backFromAllTeamTasks = () => {
    this.setState({
      displayAllTeamTasks: false,
    });
  };

  backFromAllTeamUsers = () => {
    this.setState({
      displayAllTeamUsers: false,
    });
  };

  render() {
    const {
      teamsDS,
      routesDS,
      tasksDS,
      usersDS,
      allTeamRoutesDS,
      allTeamUsersDS,
      allTeamTasksDS,
      treeListData,
      displayTeamScreen,
      displayAllTeamRoutes,
      displayAllTeamUsers,
      displayAllTeamTasks,
      teamSelected,
      selectedRowKeys,
      expandedRowKeys,
      scrollingMode,
      containersHeight,
    } = this.state;
    const { t } = this.props;
    const globalAccessLevel = getUserRole();

    return (
      <Card id="cdrTeamsMgmt" autoHeight>
        <div
          className={[
            styles.container,
            displayTeamScreen ||
            displayAllTeamRoutes ||
            displayAllTeamUsers ||
            displayAllTeamTasks
              ? styles.hide
              : "",
          ].join(" ")}
        >
          <DataGrid
            identity="grdTeamsMgmt"
            reference={this.refGridTeams}
            dataSource={teamsDS}
            showBorders={false}
            rowAlternationEnabled={false}
            columns={gridTeamsColumns()}
            onRowInserting={this.onAddTeam.bind(this)}
            onContentReady={this.setIdsGrdTeams}
            onToolbarPreparing={(e) =>
              gridTeamsToolbarPreparing(
                e,
                t,
                globalAccessLevel,
                this.handlerAddTeam,
                this.handlerDeleteTeam,
                this.handlerAllTeamRoutes,
                this.handlerAllTeamUsers,
                this.handlerAllTeamTasks,
                this.handlerExportToPDF,
                this.handlerExportToExcel
              )
            }
            onEditorPreparing={(e) => { //Limits the number of characters team description can be
              if (
                e.parentType === "dataRow" &&
                e.dataField === "TeamDescription"
              ) {
                e.editorOptions.maxLength = 150; 
              }
            }}
          >
            {[4, 3].includes(globalAccessLevel) && (
              <Editing
                mode="row"
                useIcons={true}
                allowUpdating={true}
                allowAdding={false}
              />
            )}
            {[4, 3].includes(globalAccessLevel) && (
              <Selection mode="multiple" showCheckBoxesMode="always" />
            )}
            {[4, 3].includes(globalAccessLevel) && (
              <Column
                type="buttons"
                buttons={[
                  {
                    name: "edit",
                    icon: getIcon(icons.gridEdit),
                    hint: "Edit",
                    onClick: this.handlerTeamScreen,
                  },
                ]}
                cssClass={styles.btnGridButtons}
                width="80px"
              />
            )}
            <Export fileName="gvSummary" />
          </DataGrid>
        </div>

        <div
          id="container"
          className={[
            styles.container_edit,
            !displayTeamScreen ? styles.hide : "",
          ].join(" ")}
        >
          <div className={styles.headerTeam}>
            <div className={styles.teamDescription}>
              <form>
                <Form
                  formData={this.state}
                  labelLocation="left"
                  showColonAfterLabel={true}
                  colCount={1}
                >
                  <SimpleItem
                    dataField="teamDescSelected"
                    editorType="dxTextBox"
                    isRequired={true}
                    cssClass="txtTeamDescription"
                  >
                    <RequiredRule message={t("Team Description is required")} />
                    <Label text={t("Team Description")} />
                  </SimpleItem>
                </Form>
              </form>
            </div>

            <div className={styles.butttonCommand}>
              {[4, 3].includes(globalAccessLevel) && (
                <Button
                  id="btnSaveTeam"
                  hint={t("Save Team")}
                  classes={styles.buttons}
                  imgsrc={getIcon(icons.save)}
                  onClick={() => this.onUpdateTeam(teamSelected)}
                />
              )}
              <Button
                id="btnBackToTeamsMgmt"
                hint={t("Back")}
                classes={styles.buttons}
                imgsrc={getIcon(icons.close)}
                onClick={this.handlerBackToTeams}
              />
            </div>
          </div>

          <Accordion
            id="acdTeamsMgmt"
            ref={this.refAccordion}
            collapsible={true}
            multiple={true}
            animationDuration={300}
          >
            <Item
              title={
                t("Team-Users Report") +
                " [" +
                usersDS.filter((f) => f.Selected).length +
                "]"
              }
              className={styles.container}
            >
              <div
                className={styles.usersContainer}
                style={{ height: containersHeight }}
              >
                <DataGrid
                  identity="grdTeamsMgmtUsers"
                  reference={this.refGridUsers}
                  dataSource={
                    [4, 3].includes(globalAccessLevel)
                      ? usersDS
                      : usersDS.filter((user) => user.Selected)
                  }
                  showBorders={false}
                  columnAutoWidth={true}
                  keyExpr="UserId"
                  columns={gridUsersColumns()}
                  defaultSelectedRowKeys={usersDS
                    .filter((f) => f.Selected)
                    .map((m) => m.UserId)}
                  onToolbarPreparing={(e) =>
                    gridUsersToolbarPreparing(
                      e,
                      t,
                      this.handlerExportToPDF,
                      this.handlerExportToExcel
                    )
                  }
                >
                  {[4, 3].includes(globalAccessLevel) && (
                    <Selection
                      mode="multiple"
                      showCheckBoxesMode="always"
                      allowSelectAll={true}
                    />
                  )}
                  <Export fileName="gvView" />
                </DataGrid>
              </div>
            </Item>
            <Item
              title={
                t("Team-Routes Report") +
                " [" +
                routesDS.filter((f) => f.Selected).length +
                "]"
              }
              className={styles.container}
            >
              <div
                className={styles.routesContainer}
                style={{ height: containersHeight }}
              >
                <DataGrid
                  identity="grdTeamsMgmtRoutes"
                  reference={this.refGridRoutes}
                  dataSource={
                    [4, 3].includes(globalAccessLevel)
                      ? routesDS
                      : routesDS.filter((route) => route.Selected)
                  }
                  showBorders={false}
                  columnAutoWidth={true}
                  keyExpr="RouteId"
                  columns={gridRoutesColumns()}
                  onContentReady={this.setIdsTeamRoutesGridComponents}
                  defaultSelectedRowKeys={routesDS
                    .filter((f) => f.Selected)
                    .map((m) => m.RouteId)}
                  onToolbarPreparing={(e) =>
                    gridRoutesToolbarPreparing(
                      t,
                      e,
                      this.handlerExportToPDF,
                      this.handlerExportToExcel
                    )
                  }
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
            </Item>

            <Item
              title={t("Team-Tasks Report") + " [" + tasksDS.length + "]"}
              className={styles.container}
            >
              <div
                className={styles.taskContainer}
                style={{ height: containersHeight }}
              >
                <div className={styles.taskContainerTreeList}>
                  <TreeList
                    id="trlTeamTasks"
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
                        [4, 3].includes(globalAccessLevel) ? "multiple" : "none"
                      }
                    />
                  </TreeList>
                </div>
                <div className={styles.taskContainerDataGrid}>
                  <DataGrid
                    identity="grdTeamsMgmtTasks"
                    keyExpr="ItemId"
                    reference={this.refGridTasks}
                    dataSource={tasksDS || []}
                    showBorders={false}
                    scrollingMode={scrollingMode}
                    columnResizingMode="nextColumn"
                    columnAutoWidth={true}
                    columns={gridTasksColumns()}
                    onContentReady={this.setIdsTeamTasksGridComponents}
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
                    <Template
                      name="totalRowsPerPage"
                      render={this.toolbarItemRender}
                    />
                    <Editing
                      mode="cell"
                      allowUpdating={true}
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

        <div
          className={[
            styles.container,
            !displayAllTeamRoutes ? styles.hide : "",
          ].join(" ")}
        >
          <div className={styles.infoContent}>
            <h4 className={styles.title}>
              {t("Team-Routes Report (All Teams)")}
            </h4>
          </div>

          {displayAllTeamRoutes && (
            <div className={styles.allTeamReportContainer}>
              <DataGrid
                identity="grdTeamsMgmtAllTeams"
                reference={this.refGridAllRoutes}
                dataSource={allTeamRoutesDS || []}
                showBorders={false}
                groupPanelVisible={true}
                columnAutoWidth={true}
                onToolbarPreparing={(e) =>
                  gridAllReportsToolbarPreparing(
                    e,
                    t,
                    this.backFromAllTeamRoutes,
                    this.handlerExportToPDF,
                    this.handlerExportToExcel,
                    "AllTeamRoutes"
                  )
                }
                columns={gridAllTeamRoutesColumns()}
              >
                <Paging enabled={true} pageSize={30} />
                <Pager
                  showPageSizeSelector={false}
                  showNavigationButtons={false}
                  showInfo={true}
                  visible={true}
                />
                <Export fileName="gvView" />
              </DataGrid>
            </div>
          )}
        </div>

        <div
          className={[
            styles.container,
            !displayAllTeamUsers ? styles.hide : "",
          ].join(" ")}
        >
          <div className={styles.infoContent}>
            <h4 className={styles.title}>
              {t("Team-Users Report (All Teams)")}
            </h4>
          </div>

          {displayAllTeamUsers && (
            <div className={styles.allTeamReportContainer}>
              <DataGrid
                identity="grdTeamsMgmtAllUsers"
                reference={this.refGridAllUsers}
                dataSource={allTeamUsersDS || []}
                showBorders={false}
                groupPanelVisible={true}
                columnAutoWidth={true}
                onToolbarPreparing={(e) =>
                  gridAllReportsToolbarPreparing(
                    e,
                    t,
                    this.backFromAllTeamUsers,
                    this.handlerExportToPDF,
                    this.handlerExportToExcel,
                    "AllTeamUsers"
                  )
                }
                columns={gridAllTeamUsersColumns()}
              >
                <Paging enabled={true} pageSize={30} />
                <Pager
                  showPageSizeSelector={false}
                  showNavigationButtons={false}
                  showInfo={true}
                  visible={true}
                />
                <Export fileName="gvView" />
              </DataGrid>
            </div>
          )}
        </div>

        <div
          className={[
            styles.container,
            !displayAllTeamTasks ? styles.hide : "",
          ].join(" ")}
        >
          <div className={styles.infoContent}>
            <h4 className={styles.title}>
              {t("Team-Tasks Report (All Teams)")}
            </h4>
          </div>

          {displayAllTeamTasks && (
            <div className={styles.allTeamReportContainer}>
              <DataGrid
                identity="grdTeamsMgmtAllTasks"
                reference={this.refGridAllTasks}
                dataSource={allTeamTasksDS || []}
                showBorders={false}
                groupPanelVisible={true}
                columnAutoWidth={true}
                onToolbarPreparing={(e) =>
                  gridAllReportsToolbarPreparing(
                    e,
                    t,
                    this.backFromAllTeamTasks,
                    this.handlerExportToPDF,
                    this.handlerExportToExcel,
                    "AllTeamTasks"
                  )
                }
                columns={gridAllTeamTasksColumns()}
              >
                <Paging enabled={true} pageSize={30} />
                <Pager
                  showPageSizeSelector={false}
                  showNavigationButtons={false}
                  showInfo={true}
                  visible={true}
                />
                <Export fileName="gvView" />
              </DataGrid>
            </div>
          )}
        </div>
      </Card>
    );
  }
}

export default TeamsManagement;
