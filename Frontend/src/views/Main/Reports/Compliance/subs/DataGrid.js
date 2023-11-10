import React, { Component } from "react";
import DataGrid, {
  Column,
  MasterDetail,
  Pager,
  Paging,
} from "devextreme-react/ui/data-grid";
import { getComplianceGridColumns } from "../options";
import {
  getCompliance,
  getComplianceSpecs,
} from "../../../../../services/reports";
import icons from "../../../../../resources/icons";
import { displayPreload } from "../../../../../components/Framework/Preload";
import dayjs from "dayjs";
import { isTablet } from "../../../../../utils";
import styles from "../styles.module.scss";

export default class DataGridCompliance extends Component {
  constructor(props) {
    super(props);

    this.state = {
      runTime: null,
      data: null,
      specs: [],
    };
  }

  componentDidMount = () => {
    this.loadReport();
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (this.props.runTime !== prevProps.runTime) this.loadReport();
  };

  shouldComponentUpdate(nextProps, nextState) {
    return (
      nextProps.runTime !== this.props.runTime ||
      nextState.runTime !== this.state.runTime
    );
  }

  loadReport = () => {
    var filters = this.props.refFilters.current.state;

    var params =
      filters.rdgGranularity >= 3
        ? this.buildParamsForPlantModel(this.props.detailData)
        : this.buildParamsForRoutesAndTeams(this.props.detailData);

    var granularity =
      this.props.detailData !== null ? this.props.detailData.Granularity : 3;

    displayPreload(true);
    getCompliance(params).then((response) => {
      response = response ?? [];

      displayPreload(false);
      getComplianceSpecs(
        granularity,
        response.map((x) => x.ItemId).join(","),
        dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss"),
        dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss")
      ).then((specs) => {
        this.setState({
          data: response,
          specs: specs,
          runTime: new Date(),
        });
      });
    });
  };

  buildParamsForPlantModel = (e) => {
    let filters = this.props.refFilters.current.state;

    let topLevelId = 0;
    let selectionItemId = 0;
    if (e === null && filters.rdgGranularity > 3) {
      //Has Selection Filters
      const { departments, lines, units } = filters.plantModel;

      topLevelId =
        filters.rdgGranularity === 4
          ? departments.toString()
          : filters.rdgGranularity === 5
          ? lines.toString()
          : filters.rdgGranularity === 6
          ? units.toString()
          : 0;

      // selectionItemId =
      //   filters.rdgGranularity === 4
      //     ? departments.toString()
      //     : filters.rdgGranularity === 5
      //     ? lines.toString()
      //     : filters.rdgGranularity === 6
      //     ? units.toString()
      //     : 0;
    }

    let granularity =
      e !== null
        ? e.Granularity + e.SubLevel
        : selectionItemId !== 0
        ? filters.rdgGranularity - 1
        : filters.rdgGranularity;

    let params = {};

    params.granularity = granularity;
    params.topLevelId = e !== null ? e.ItemId : topLevelId;
    params.subLevel = e !== null || selectionItemId !== 0 ? 1 : 0;
    params.startTime = dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss");
    params.endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");
    params.routeIds = "";
    params.teamIds = "";
    params.teamDetails = 0;
    params.qFactorOnly = filters.chkQFactor;
    params.selectionItemId = selectionItemId;
    params.HSEOnly = filters.HSETasks;
    // params.MinimumUptimeOnly = filters.chkMinimumUptime;

    return params;
  };

  buildParamsForRoutesAndTeams = (e) => {
    const {
      isTeamsPlantModel,
      isTeamsSummary,
      isRouteMasterDetail,
      isDepartmentMasterDetail,
    } = this.props;
    let filters = this.props.refFilters.current.state;
    const { plantModel } = filters;

    let routesIds =
      filters.rdgEntryType === "My Routes"
        ? plantModel.myroutes.join(",")
        : plantModel.routes.join(",");

    let teamsIds =
      filters.rdgEntryType === "My Teams"
        ? plantModel.myteams.join(",")
        : plantModel.teams.join(",");

    let params = {};

    params.granularity = filters.rdgGranularity;
    params.topLevelId = e !== null ? e.ItemId : 0;
    // params.subLevel = e !== null ? e.SubLevel + 1 : 0;

    let isRouteDetails =
      isRouteMasterDetail !== undefined
        ? true
        : isDepartmentMasterDetail !== undefined
        ? false
        : filters.chkRouteDetails;

    // if (!filters.chkRouteDetails) {
    if (!isRouteDetails) {
      params.subLevel =
        e !== null ? (e.SubLevel > 1 ? e.SubLevel + 1 : e.SubLevel + 7) : 0;
    } else {
      params.subLevel = e !== null ? e.SubLevel + 1 : 0;
    }

    params.startTime = dayjs(filters.dtStartTime).format("YYYY-MM-DD HH:mm:ss");
    params.endTime = dayjs(filters.dtEndTime).format("YYYY-MM-DD HH:mm:ss");
    params.routeIds = e !== null ? e.RouteIds ?? "" : routesIds;
    params.teamIds = e !== null ? e.TeamIds ?? "" : teamsIds;
    params.teamDetails =
      isTeamsPlantModel !== undefined
        ? 4
        : isTeamsSummary !== undefined
        ? 1
        : 2;
    params.qFactorOnly = filters.chkQFactor;
    params.HSEOnly = filters.HSETasks;
    // params.MinimumUptimeOnly = filters.chkMinimumUptime;

    return params;
  };

  render() {
    const { t, caption, masterDetailTemplate } = this.props;
    const { data, specs } = this.state;

    if (data?.length === 0)
      return (
        <div className={styles.noDataMessage}>
          <img alt="" src={icons.info} />
          <label>{t("No data to display for the current selection.")}</label>
        </div>
      );

    return (
      <div>
        <DataGrid
          id="dgrCompliance"
          ref={this.props.reference}
          dataSource={data}
          showBorders={true}
          allowColumnReordering={false}
          allowColumnResizing={false}
          columnAutoWidth={true}
          searchPanelVisible={false}
          columnResizingMode={"nextColumn"}
        >
          <Pager visible={false} />
          <Paging enabled={false} />
          {
            // eslint-disable-next-line
            getComplianceGridColumns().map((col) => {
              if (
                !(
                  (isTablet() &&
                    col.dataField === "eMagReport" &&
                    (caption === "Site" ||
                      caption === "Department" ||
                      caption === "Line" ||
                      caption === "Master Equiptment")) ||
                  (isTablet() &&
                    caption === "Task" &&
                    (col.dataField === "Fl3" || col.dataField === "Fl4"))
                )
              )
                return (
                  <Column
                    key={col.caption}
                    caption={
                      col.caption === "Level" ? t(caption) : t(col.caption)
                    }
                    dataField={col.dataField}
                    sortOrder={col.sortOrder}
                    width={col.width}
                    visible={col.level === "All" ? true : col.level === caption}
                    cellTemplate={(container, data) => {
                      if (
                        (caption === "Module" &&
                          col.dataField === "eMagReport") ||
                        (caption === "Task" && col.dataField === "eMagReport")
                      ) {
                        var chart =
                          caption === "Module"
                            ? icons.gridEmag
                            : icons.gridTrend;
                        var title =
                          caption === "Module"
                            ? "Show eMag Report"
                            : "Show Trend Report";

                        let j = document.createElement("img");
                        j.setAttribute("src", chart);
                        j.setAttribute("title", title);
                        j.setAttribute("style", "cursor:pointer;");
                        j.setAttribute(
                          "id",
                          caption === "Module"
                            ? "btnShowEmagReport-" + data.rowIndex
                            : "btnShowTrendReport-" + data.rowIndex
                        );
                        container.setAttribute("style", "text-align: center;");

                        j.onclick = () => {
                          caption === "Module"
                            ? this.props.handlerEMagReport(data.data)
                            : this.props.handlerEMagTrendReport(data.data);
                        };
                        container.appendChild(j);
                      } else if (
                        col.specName === "Defects Found" ||
                        col.specName === "Done Late" ||
                        col.specName === "Number Missed" ||
                        col.specName === "Opened Defects" ||
                        col.specName === "Pct Done" ||
                        col.specName === "Stops"
                      ) {
                        let j = document.createElement("span");

                        //PctDone: tasks with 0 for Total Count should show as '---' or blank
                        if (
                          col.specName === "Pct Done" &&
                          data.data.TotalCount <= 0
                        ) {
                          j.appendChild(document.createTextNode("---"));
                          container.appendChild(j);
                          return;
                        }

                        j.appendChild(
                          document.createTextNode(data.value ?? "")
                        );

                        if (specs && Array.isArray(specs) && specs.length > 0) {
                          var spec = specs?.find(
                            (x) => x.SpecName === col.specName
                          );
                          //  'Evaluate Lower Reject Limit
                          if (
                            spec?.Lr &&
                            parseFloat(data.value) < parseFloat(spec?.Lr)
                          ) {
                            j.classList.add(styles.lowerReject);
                          }
                          // 'Evaluate Lower Warning Limit
                          else if (
                            spec?.Lw &&
                            parseFloat(data.value) < parseFloat(spec?.Lw)
                          ) {
                            j.classList.add(styles.lowerWarning);
                          }
                          // 'Evaluate Lower User Limit
                          else if (
                            spec?.Lu &&
                            parseFloat(data.value) < parseInt(spec?.Lu)
                          ) {
                            j.classList.add(styles.lowerUser);
                          }
                          // 'Evaluate Upper Reject Limit
                          else if (
                            spec?.Ur &&
                            parseFloat(data.value) > parseInt(spec?.Ur)
                          ) {
                            j.classList.add(styles.upperReject);
                          }
                          // Evaluate Upper Warning Limit
                          else if (
                            spec?.Uw &&
                            parseFloat(data.value) > parseInt(spec?.Uw)
                          ) {
                            j.classList.add(styles.upperWarning);
                          }
                          // 'Evaluate Upper User Limit
                          else if (
                            spec?.Uu &&
                            parseFloat(data.value) > parseInt(spec?.Uu)
                          ) {
                            j.classList.add(styles.upperUser);
                          }
                        }

                        container.appendChild(j);
                      } else {
                        let j = document.createElement("span");
                        j.appendChild(
                          document.createTextNode(data.value ?? "")
                        );
                        container.appendChild(j);
                      }
                    }}
                  />
                );
            })
          }
          {masterDetailTemplate && (
            <MasterDetail
              enabled={true}
              component={masterDetailTemplate}
              // autoExpandAll={true}
            >
              <Pager visible={false} />
              <Paging enabled={false} />
            </MasterDetail>
          )}
        </DataGrid>
      </div>
    );
  }
}
