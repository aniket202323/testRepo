import React, { PureComponent } from "react";
import Filters from "./subs/Filters";
import DataGrid from "./subs/DataGrid";
import ListItems from "./subs/ListItems-Tails";
import Defects from "./subs/Defects";
import Card from "../../../components/Card";
import Button from "../../../components/Button";
import {
  getLineTasksSelection,
  getTeamsTasksSelection,
  getRoutesTasksSelection,
} from "../../../services/tasks";
import {
  getTourStopInfo,
  getTourStop,
  // getOpsHubServer,
} from "../../../services/tourStops";
import { setBreadcrumbEvents } from "../../../components/Framework/Breadcrumb/events";
import { displayPreload } from "../../../components/Framework/Preload";
import { getDefaultViews } from "../../../components/CustomView/Dialog/index";
import { filterGrid } from "./options";
import DataSource from "devextreme/data/data_source";
import { VIEW } from "../../../utils/constants";
import { isTablet } from "../../../utils";
import Icon from "../../../components/Icon";
import styles from "./styles.module.scss";

const initialState = {
  data: [],
  dataFilteredTails: [],
  showFilters: true,
  showGrid: false,
  showDefects: false,
  navbarClosed: false,
  qrCodeNotFound: false,
  needToLoadFromOpshub: false,
  tourMaps: [],
};

class TasksSelection extends PureComponent {
  constructor(props) {
    super(props);

    this.refFilters = React.createRef();
    this.refDefects = React.createRef();
    this.refGridComponent = React.createRef();
    this.refTailsComponent = React.createRef();

    this.state = {
      ...initialState,
      loadStateStoring: false,
    };
  }

  componentDidMount = () => {
    this.setBreadcrumb();
    let isRoute = this.props.urlParams?.isRoute || "";
    // let byRoute = this.props.urlParams?.myroute;
    if (isRoute.includes("false")) {
      setTimeout(() => {
        this.props.updateSettings({
          navbar: {
            opened: false,
            group: "Tasks Selection",
            itemSelected: "Plant Model",
          },
        });
      }, 100);
    }
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (prevProps.viewActive !== this.props.viewActive) {
      this.setBreadcrumb();
      this.clearState();
    }
  };

  clearState = () => {
    this.setState({ ...initialState }, () => {
      this.refFilters.current.clearState();
      this.refDefects.current.clearState();
    });
  };

  setBreadcrumb = (routeDesc = null) => {
    setBreadcrumbEvents(
      <div className={styles.breadcrumb}>
        {routeDesc !== null && <span>{"> " + routeDesc}</span>}
        <nav>
          <Button
            id="btnShowHideFiltersTasksSelection"
            icon="filter"
            hint="Show/Hide Filters"
            primary
            classes={[
              styles.breadcrumbButton,
              "taskSelectionBreadcrumbButton",
            ].join(" ")}
            onClick={this.handlerFilters}
          />
          <Button
            id="btnRunTasksSelection"
            icon="rocket"
            hint="Execute"
            primary
            disabled={false}
            classes={styles.breadcrumbButton}
            onClick={() => this.handlerData(false)}
          />
        </nav>
        {/* {sessionStorage.getItem("OpsHubPage") !== null && (
          <div className={styles.clNotificationMessage}>
            <Icon name="circle-info" />
            <label>
              Please ensure you've selected the appropriate lines in My Machines
            </label>
          </div>
        )} */}
      </div>
    );
  };

  addRouteDescInHeader = (route) => {
    route && this.setBreadcrumb(route.RouteDesc);
  };

  handlerFilters = () => {
    this.setState({ showFilters: !this.state.showFilters }, () => {
      if (!isTablet()) this.applyFiltersGrid();
    });
  };

  handlerDefects = (dataSaved = false, task) => {
    const { showDefects, showFilters, showGrid } = this.state;
    this.setState(
      {
        showDefects: !showDefects,
        showFilters: !showFilters,
        showGrid: !showGrid,
      },
      () => {
        let btnvisibility = !showDefects ? "hidden" : "visible";
        document.getElementById(
          "btnShowHideFiltersTasksSelection"
        ).style.visibility = btnvisibility;

        document.getElementById("btnRunTasksSelection").style.visibility =
          btnvisibility;

        if (dataSaved) {
          let refGrid =
            this.refGridComponent.current?.refGrid.current?.instance;
          let refTailsComponent =
            this.refTailsComponent.current?.refList.current?.instance;
          let currentData = this.state.data;

          if (currentData) {
            let taskEdited = currentData.find((j) => j.TestId === task.TestId);
            taskEdited.CurrentResult = task?.CurrentResult;
            taskEdited.NbrDefects = task?.NbrDefects;
          }

          refGrid && !refTailsComponent
            ? refGrid.saveEditData()
            : refTailsComponent._refresh();
        }
      }
    );
  };

  hasCLTasks = (tasks, tourStopId = undefined) => {
    if (!tasks) return;
    if (tourStopId)
      tasks = tasks.filter((t) => t.TourId === parseInt(tourStopId));
    return tasks.some((x) => x?.EventSubtypeDesc !== "eCIL");
  };

  handlerData = (refresh = false, filterByUrl = null) => {
    this.setState({ showFilters: false, needToLoadFromOpshub: false }, () => {
      const filters = this.refFilters.current?.state;
      const { viewActive } = this.props;
      let linesSelected = filters.selected.lines;

      setTimeout(() => {
        displayPreload(true);
      }, 500);

      let gridInstance =
        this.refGridComponent.current?.refGrid.current?.instance;

      if (!isTablet() && !refresh && gridInstance) {
        //set grid configs
        gridInstance.pageIndex(0);
        gridInstance.clearFilter();
        gridInstance.clearSorting();
        gridInstance.clearGrouping();
        gridInstance.cancelEditData();
      }

      if ((!this.state.loadStateStoring || !refresh) && gridInstance) {
        let defaultView = getDefaultViews();
        if (defaultView !== null) {
          gridInstance.state(JSON.parse(defaultView.Data));
          this.setState({ loadStateStoring: true });
        }
      }

      this.setState({ data: [] }, () => {
        if (viewActive === VIEW.TASK_SELECTION.PlantModel) {
          if (!this.state.navbarClosed)
            this.props.updateSettings({
              navbar: { opened: false },
            });

          if (linesSelected.length > 0) {
            getLineTasksSelection(linesSelected.join(",")).then((data) => {
              if (isTablet()) {
                this.handlerTailsData(filterByUrl, data);
                setTimeout(() => {
                  displayPreload(false);
                }, 500);
              } else {
                data = this.setFormatEventSubtypeDesc(data) || [];
                this.setState(
                  {
                    data,
                    showGrid: true,
                    navbarClosed: true,
                    showFilters: data?.length === 0,
                  },
                  () =>
                    setTimeout(() => {
                      this.applyFiltersGrid();
                      if (filterByUrl !== null)
                        this.filterByUrl(filterByUrl, data);
                      else displayPreload(false);
                    }, 1000)
                );
              }
            });
          } else {
            this.setState({ data: [] }, () => displayPreload(false));
          }
        }

        if (viewActive === VIEW.TASK_SELECTION.MyTeams) {
          if (filters.selected.myteams.length) {
            getTeamsTasksSelection(filters.selected.myteams.join(",")).then(
              (response) =>
                this.setState(
                  {
                    data: this.setFormatEventSubtypeDesc(response),
                    showGrid: true,
                    showFilters: response?.length === 0,
                  },
                  () =>
                    setTimeout(() => {
                      displayPreload(false);
                    }, 1000)
                )
            );
          } else {
            this.setState({ data: [] }, () => displayPreload(false));
          }
        }

        if (viewActive === VIEW.TASK_SELECTION.Teams) {
          if (filters.selected.teams.length) {
            getTeamsTasksSelection(filters.selected.teams.join(",")).then(
              (response) =>
                this.setState(
                  {
                    data: this.setFormatEventSubtypeDesc(response),
                    showGrid: true,
                    showFilters: response?.length === 0,
                  },
                  () =>
                    setTimeout(() => {
                      displayPreload(false);
                    }, 1000)
                )
            );
          } else {
            this.setState({ data: [] }, () => displayPreload(false));
          }
        }

        if (viewActive === VIEW.TASK_SELECTION.MyRoutes) {
          let myroutesSelected = filters.selected.myroutes;
          if (myroutesSelected?.length) {
            getRoutesTasksSelection(myroutesSelected.join(",")).then(
              (response) => {
                if (!this.checkIsLoadingFromOpsHub(response, filterByUrl))
                  return;

                this.setTourStopInfo(myroutesSelected, response, filterByUrl);

                if (!response?.length) {
                  this.setState(
                    {
                      data: [],
                      tourMaps: [],
                      showFilters: response?.length === 0,
                    },
                    () => {
                      setTimeout(() => {
                        displayPreload(false);
                      }, 1000);
                    }
                  );
                  return;
                }
              }
            );
          } else {
            this.setState(
              {
                data: [],
                tourMaps: [],
                qrCodeNotFound: true,
                showGrid: true,
                showFilters: true,
              },
              () => {
                setTimeout(() => {
                  displayPreload(false);
                }, 1000);
              }
            );
          }
        }

        if (viewActive === VIEW.TASK_SELECTION.Routes) {
          let routesSelected = filters.selected.routes;
          if (routesSelected?.length) {
            getRoutesTasksSelection(filters.selected.routes.join(",")).then(
              (response) => {
                if (!this.checkIsLoadingFromOpsHub(response, filterByUrl)) {
                  return;
                }

                this.setTourStopInfo(routesSelected, response, filterByUrl);

                if (!response?.length) {
                  this.setState(
                    {
                      data: [],
                      tourMaps: [],
                      showFilters: response?.length === 0,
                    },
                    () => {
                      setTimeout(() => {
                        displayPreload(false);
                      }, 1000);
                    }
                  );
                  return;
                }
              }
            );
          } else {
            this.setState({ data: [] }, () => displayPreload(false));
          }
        }
      });
    });
  };

  setTourStopInfo = (routesSelected, response, filterByUrl) => {
    if (!response?.length) {
      this.setState(
        {
          data: [],
          tourMaps: [],
          showGrid: true,
          showFilters: true,
        },
        () => {
          setTimeout(() => {
            displayPreload(false);
          }, 1000);
        }
      );
      return;
    } else {
      displayPreload(true);
      getTourStopInfo(routesSelected[0]).then((ts) => {
        if (!ts) {
          displayPreload(false);
          return;
        }
        let temp1 = {};
        let temp2 = {};
        response?.forEach((t) => {
          temp2 = ts.find((y) => y.VarId === t.VarId);
          if (temp2) {
            t.TourTaskOrder = temp2.TourTaskOrder;
            t.TourDesc =
              temp2.TourOrder !== 0
                ? "(" + temp2.TourOrder + ") " + (temp2.TourDesc || "")
                : "Unassigned";
          }
        });

        getTourStop(routesSelected[0]).then((ts_maps) => {
          response?.forEach((t) => {
            temp1 = ts_maps.find((y) => y.TourId === t.TourId);
            if (temp1 && t.TourMap) t.TourMap = temp1.TourMap;
          });
          this.setState(
            {
              data: this.setFormatEventSubtypeDesc(response),
              showGrid: true,
              tourMaps: ts_maps,
              showFilters: response?.length === 0,
            },
            () =>
              setTimeout(() => {
                if (filterByUrl) {
                  let hasTourStopAssociated = ts_maps.find(
                    (p) => p.TourId === parseInt(filterByUrl)
                  );
                  let refComponent = isTablet()
                    ? this.refTailsComponent.current
                    : this.refGridComponent.current;
                  if (refComponent)
                    refComponent?.accordionHandler(
                      hasTourStopAssociated,
                      false
                    );
                  this.filterByUrl(filterByUrl, response);
                } else displayPreload(false);
              }, 1000)
          );
          //
        });
      });
    }
  };

  setFormatEventSubtypeDesc = (data) => {
    data.forEach((item) => {
      item.EventSubtypeDesc =
        item.EventSubtypeDesc !== "eCIL" && item.EventSubtypeDesc !== ""
          ? "CL"
          : "eCIL";
    });
    return data;
  };

  checkIsLoadingFromOpsHub = (response, tourStopId) => {
    if (
      this.hasCLTasks(response, tourStopId) &&
      !sessionStorage.getItem("OpsHubPage")
    ) {
      this.setState({ needToLoadFromOpshub: true, showFilters: true }, () =>
        setTimeout(() => {
          displayPreload(false);
        }, 500)
      );
      return false;
    }
    return true;
  };

  handlerDataByQr = (tasksIds, qrCodeNotFound = false) => {
    let currentUrl = window.location.href;
    currentUrl =
      currentUrl.substr(0, currentUrl.toLowerCase().indexOf("client/")) +
      "Client/";
    window.history.replaceState({}, document.title, currentUrl);
    setTimeout(() => {
      displayPreload(false);
    }, 200);
    if (qrCodeNotFound) {
      this.setState({
        qrCodeNotFound: true,
      });
    } else this.handlerData(false, tasksIds ? tasksIds : null);
  };

  applyFiltersGrid = () => {
    this.refGridComponent.current?.refGrid.current?.instance.refresh();

    this.refGridComponent.current?.handlerFilterGrid(
      filterGrid(this.refFilters.current?.state)
    );
  };

  filterByUrl = (ids, ds) => {
    let result = this.filterDataByUrlIds(ids, ds);
    this.setState(
      {
        data: result,
        showFilters: result?.length === 0,
      },
      () => {
        let refGrid = this.refGridComponent.current?.refGrid.current?.instance;
        refGrid?.refresh();
        setTimeout(() => {
          displayPreload(false);
        }, 500);
      }
    );
  };

  handlerTailsData = async (ids = null, response) => {
    let filter = filterGrid(this.refFilters.current.state);
    let data = await new DataSource({
      store: [...response],
      filter,
      paginate: false,
    }).load();
    if (ids !== null) data = this.filterDataByUrlIds(ids, data);
    this.setState({
      data,
      showGrid: true,
      showFilters: response?.length === 0,
    });
  };

  filterDataByUrlIds = (ids, ds) => {
    let tourStopId = this.props.urlParams?.tourStopId || null;
    let result = [];

    ids &&
      ids.split(",").forEach((id) => {
        let temp = ds.filter(
          (y) => y[tourStopId ? "TourId" : "VarId"] === parseInt(id)
        );
        result = result.concat(temp);
      });
    return result;
  };

  render() {
    const { t, viewActive, urlParams } = this.props;
    const {
      data,
      showFilters,
      showGrid,
      showDefects,
      qrCodeNotFound,
      needToLoadFromOpshub,
      tourMaps,
    } = this.state;

    let isMyRouteOrMobility =
      sessionStorage.getItem("OpsHubPage") === "MyRoutes" || isTablet();
    return (
      <div id="taskselection" className={styles.container}>
        <Card
          id="crdTasksSelectionFilters"
          hidden={!showFilters || showDefects}
        >
          <div
            style={{
              display: isMyRouteOrMobility ? "inline-flex" : "block",
            }}
          >
            <Filters
              t={t}
              ref={this.refFilters}
              handlerFilters={this.handlerFilters}
              handlerData={this.handlerData}
              handlerDataByQr={this.handlerDataByQr}
              refGridComponent={this.refGridComponent}
              viewActive={viewActive}
              urlParams={urlParams}
              addRouteDescInHeader={this.addRouteDescInHeader}
            />
            <Button
              id="btnRunTasksSelectionMyRoutes"
              icon="rocket"
              hint="Execute"
              primary
              disabled={false}
              classes={styles.breadcrumbButton}
              onClick={() => this.handlerData(false)}
              style={{
                marginBottom: "5px",
                alignSelf: "self-end",
                display: isMyRouteOrMobility ? "content" : "none",
              }}
            />
          </div>
          {qrCodeNotFound && (
            <div className={styles.qrCodedNotFound}>
              <label>
                {t("The QR Code is not associated with the current user.")}
              </label>
            </div>
          )}
        </Card>
        {needToLoadFromOpshub && (
          <Card>
            <div className={styles.isDefectLookedMessage}>
              <Icon name="circle-info" />
              <label>
                {t(
                  "This is an integrated tour route which includes CL tasks and needs to be accessed from MyProficy."
                )}
              </label>
            </div>
          </Card>
        )}
        {!needToLoadFromOpshub && (
          <Card
            id="crdTasksSelectionGrid"
            classes={isTablet() ? styles.cardDevice : styles.cardDesktop}
            hidden={!showGrid}
          >
            {isTablet() ? (
              <ListItems
                t={t}
                ref={this.refTailsComponent}
                refDefects={this.refDefects.current}
                data={data}
                viewActive={viewActive}
                handlerData={this.handlerData}
                handlerDefects={this.handlerDefects}
                tourMaps={tourMaps}
                handlerFilters={this.handlerFilters}
              />
            ) : (
              <DataGrid
                t={t}
                ref={this.refGridComponent}
                refFilters={this.refFilters.current?.state}
                refDefects={this.refDefects.current}
                handlerData={this.handlerData}
                handlerDefects={this.handlerDefects}
                applyFiltersGrid={this.applyFiltersGrid}
                viewActive={viewActive}
                data={data}
                urlParams={urlParams}
                tourMaps={tourMaps}
                handlerFilters={this.handlerFilters}
                // showEditorAlways={true}
              />
            )}
          </Card>
        )}
        <Card id="crdTasksSelectionDefects" autoHeight hidden={!showDefects}>
          <Defects
            t={t}
            ref={this.refDefects}
            showDefects={showDefects}
            handlerDefects={this.handlerDefects}
          />
        </Card>
      </div>
    );
  }
}

export default TasksSelection;
