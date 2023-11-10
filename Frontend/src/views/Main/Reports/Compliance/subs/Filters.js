import React, { PureComponent } from "react";
import Panel from "../../../../../components/Panel";
import DateTime from "../../../../../components/DateTime";
import RadioGroup from "../../../../../components/RadioGroup";
import SelectBox from "../../../../../components/SelectBox";
import CheckBox from "../../../../../components/CheckBox";
import {
  getDepartments,
  getLines,
  getUnits,
} from "../../../../../services/plantModel";
import { getTimeFrames } from "../../../../../services/application";
import { getTeams, getMyTeams } from "../../../../../services/teams";
import { getRoutes, getMyRoutes } from "../../../../../services/routes";
import { getUserRole } from "../../../../../services/auth";
import { updatePlantModelView } from "../options";
import { CUSTOM_PERIOD, GRANULARITY } from "../../../../../utils/constants";
import { setIdsByClassName } from "../../../../../utils/index";
import { Icon } from "react-fa";
import styles from "../styles.module.scss";
import { displayPreload } from "../../../../../components/Framework/Preload";

const initialState = {
  data: [],
  rdgEntryType: "Plant Model",
  rdgGranularity: GRANULARITY.Site,
  rdgTimeFrame: CUSTOM_PERIOD.Last30Days,
  rdgTeamsDetails: 1,
  chkRouteDetails: true,
  chkPlantModelDetails: false,
  chkQFactor: false,
  // chkMinimumUptime: false,
  HSETasks: false,
  dtStartTime: null,
  dtEndTime: null,
  departments: [],
  lines: [],
  units: [],
  teams: [],
  myteams: [],
  routes: [],
  myroutes: [],
  plantModel: {
    departments: [],
    lines: [],
    units: [],
    teams: [],
    myteams: [],
    routes: [],
    myroutes: [],
  },
  loading: {
    departments: false,
    myroutes: false,
    myteams: false,
  },
};

class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      ...initialState,
      timeFrames: [],
    };
  }

  componentDidMount = () => {
    displayPreload(true);
    getTimeFrames().then((response) => {
      var timeFrame =
        response?.find((tm) => tm.TimeFrameId === this.state.rdgTimeFrame) ??
        [];
      this.setState(
        {
          timeFrames: response,
          dtStartTime: timeFrame?.StartTime,
          dtEndTime: timeFrame?.EndTime,
        },
        () => displayPreload(false)
      );
    });
  };

  componentDidUpdate = (prevProps, prevState) => {
    const {
      myteams,
      teams,
      myroutes,
      routes,
      rdgEntryType,
      rdgGranularity,
      plantModel,
    } = this.state;

    if (rdgEntryType === "Plant Model") {
      if (rdgGranularity !== GRANULARITY.Site) {
        const { departments, lines } = plantModel;
        const { departments: prevDepartments, lines: prevLines } =
          prevState.plantModel;

        if (
          this.state.departments.length === 0 &&
          !this.state.loading.departments
        ) {
          getDepartments().then((response) =>
            this.setState({
              departments: response,
              loading: {
                ...this.state.loading,
                departments: true,
              },
            })
          );
        }

        if (
          (prevDepartments !== departments ||
            prevState.rdgGranularity !== rdgGranularity) &&
          departments.length > 0 &&
          rdgGranularity !== GRANULARITY.Department
        ) {
          getLines(departments.join(", ")).then((response) =>
            this.setState({ lines: response })
          );
        }

        if (
          (prevLines !== lines ||
            prevState.rdgGranularity !== rdgGranularity) &&
          lines.length > 0 &&
          rdgGranularity === GRANULARITY.MasterUnit
        ) {
          getUnits(lines.join(", ")).then((response) =>
            this.setState({ units: response })
          );
        }
      }
    }

    if (rdgEntryType === "My Teams") {
      if (myteams.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getMyTeams().then((response) =>
          this.setState({
            myteams: response,
            loading: {
              ...this.state.loading,
              myteams: true,
            },
          })
        );
      }
    }

    if (rdgEntryType === "Teams Selection") {
      if (teams.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getTeams().then((response) => this.setState({ teams: response }));
      }
    }

    if (rdgEntryType === "My Routes") {
      if (myroutes.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getMyRoutes().then((response) =>
          this.setState({
            myroutes: response,
            loading: {
              ...this.state.loading,
              myroutes: true,
            },
          })
        );
      }
    }

    if (rdgEntryType === "Routes Selection") {
      if (routes.length === 0 && rdgEntryType !== prevState.rdgEntryType) {
        getRoutes().then((response) => this.setState({ routes: response }));
      }
    }

    this.setComponentsIds();
    this.disabledToRun();
  };

  disabledToRun = () => {
    const {
      rdgEntryType,
      rdgGranularity,
      plantModel,
      chkRouteDetails,
      chkPlantModelDetails,
    } = this.state;
    const {
      departments: depts,
      lines,
      units,
      myteams,
      teams,
      myroutes,
      routes,
    } = plantModel;

    var disabled = false;
    if (rdgEntryType === "Plant Model") {
      if (
        (rdgGranularity === GRANULARITY.Department && depts.length === 0) ||
        (rdgGranularity === GRANULARITY.Line && lines.length === 0) ||
        (rdgGranularity === GRANULARITY.MasterUnit && units.length === 0)
      ) {
        disabled = true;
      }
    } else if (
      (rdgEntryType === "My Teams" && myteams.length === 0) ||
      (!chkRouteDetails && !chkPlantModelDetails)
    ) {
      disabled = true;
    } else if (
      (rdgEntryType === "Teams Selection" && teams.length === 0) ||
      (!chkRouteDetails && !chkPlantModelDetails)
    ) {
      disabled = true;
    } else if (rdgEntryType === "My Routes" && myroutes.length === 0) {
      disabled = true;
    } else if (rdgEntryType === "Routes Selection" && routes.length === 0) {
      disabled = true;
    }

    document.getElementById("btnRunReport").disabled = disabled;
    document.getElementById("btnRunPrint").disabled = disabled;
  };

  handlerRgdEntryType = (e) => {
    const { chkRouteDetails, chkPlantModelDetails } = this.state;

    var timeFrame = this.state.timeFrames.find(
      (tm) => tm.TimeFrameId === initialState.rdgTimeFrame
    );

    this.setState({
      ...initialState,
      rdgEntryType: e.value,
      rdgGranularity: e.value.includes("Teams")
        ? GRANULARITY.Team
        : e.value.includes("Routes")
        ? GRANULARITY.Route
        : GRANULARITY.Site,
      rdgTeamsDetails: e.value.includes("Routes")
        ? 2
        : e.value === "Plant Model"
        ? 4
        : e.value === "My Teams"
        ? 1
        : chkRouteDetails
        ? 2
        : chkPlantModelDetails
        ? 4
        : 1,
      dtStartTime: timeFrame.StartTime,
      dtEndTime: timeFrame.EndTime,
    });
  };

  handlerRgdTimeFrame = (e) => {
    let timeFrame;
    if (e.value !== CUSTOM_PERIOD.UserDefined)
      timeFrame = this.state.timeFrames.find(
        (tf) => tf.TimeFrameId === e.value
      );

    this.setState({
      rdgTimeFrame: e.value,
      dtStartTime:
        e.value === CUSTOM_PERIOD.UserDefined
          ? new Date(new Date().setHours(6, 0, 0))
          : timeFrame.StartTime,
      dtEndTime:
        e.value === CUSTOM_PERIOD.UserDefined ? new Date() : timeFrame.EndTime,
    });
  };

  handlerRgdGranularity = (e) => {
    if (e.value === "Site")
      this.setState({
        departments: [],
        lines: [],
        units: [],
        rdgGranularity: e.value,
        plantModel: {
          ...this.state.plantModel,
          departments: [],
          lines: [],
          units: [],
        },
      });
    else this.setState({ rdgGranularity: e.value });
  };

  handlerCheckBox = (e) => {
    this.setState({
      [e.tag]: e.value,
    });
  };

  handlerCheckBoxTeams = (e) => {
    const { chkRouteDetails, chkPlantModelDetails } = this.state;

    var chkrd, chkpm;
    chkrd = e.tag === "chkRouteDetails" ? e.value : chkRouteDetails;
    chkpm = e.tag === "chkPlantModelDetails" ? e.value : chkPlantModelDetails;

    this.setState({
      [e.tag]: e.value,
      rdgTeamsDetails: chkrd && chkpm ? 2 : chkrd ? 2 : chkpm ? 4 : 0,
    });
  };

  handlerSelectBox = (key, values) => {
    if (key.includes("teams") || key.includes("routes")) {
      this.setState({
        plantModel: { ...this.state.plantModel, [key]: values },
      });
    } else {
      let filters = updatePlantModelView(key, values, this.state);
      this.setState({ plantModel: { ...this.state.plantModel }, ...filters });
    }
  };

  handleInputDate = (e, elemName) => {
    this.setState(
      {
        [elemName]: e.value,
      },
      () => {
        if (
          new Date(this.state.dtStartTime).getTime() >=
          new Date(this.state.dtEndTime).getTime()
        ) {
          this.setState({ dtEndTime: this.state.dtStartTime });
        }
      }
    );
  };

  setComponentsIds = () => {
    setIdsByClassName([
      {
        idContainer: "pnlComplianceSelectionType",
        class: "dx-item dx-radiobutton",
        ids: ["rbnSelectionTypeCompliance"],
        same: true,
      },
      {
        idContainer: "pnlCompliancePlantModelSelection",
        class: "dx-item dx-radiobutton",
        ids: ["rbnGranularityCompliance"],
        same: true,
      },
      {
        idContainer: "pnlCompliancePeriodSelection",
        class: "dx-item dx-radiobutton",
        ids: ["rbnPeriodSelectionCompliance"],
        same: true,
      },
      // SelectBox Input & Buttons
      {
        idContainer: "sboDepartmentsCompliance",
        tagName: "input",
        ids: ["txtSearchsboDepartmentsCompliance"],
      },
      {
        idContainer: "sboLinesCompliance",
        tagName: "input",
        ids: ["txtSearchSboLinesCompliance"],
      },
      {
        idContainer: "sboUnitsCompliance",
        tagName: "input",
        ids: ["txtSearchSboUnitsCompliance"],
      },
      {
        idContainer: "sboMyTeams",
        tagName: "input",
        ids: ["txtSearchSboMyTeamsCompliance"],
      },
      {
        idContainer: "sboMyTeams",
        tagName: "button",
        ids: ["btnSelectAllSboMyTeamsCompliance"],
      },
      {
        idContainer: "sboTeams",
        tagName: "input",
        ids: ["txtSearchSboTeamsCompliance"],
      },
      {
        idContainer: "sboTeams",
        tagName: "button",
        ids: ["btnSelectAllSboTeamsCompliance"],
      },
      {
        idContainer: "sboMyRoutes",
        tagName: "input",
        ids: ["txtSearchSboMyRoutesCompliance"],
      },
      {
        idContainer: "sboMyRoutes",
        tagName: "button",
        ids: ["btnSelectAllSboMyRoutesCompliance"],
      },
      {
        idContainer: "sboRoutes",
        tagName: "input",
        ids: ["txtSearchSboRoutesCompliance"],
      },
      {
        idContainer: "sboRoutes",
        tagName: "button",
        ids: ["btnSelectAllSboRoutesCompliance"],
      },
    ]);
  };

  render() {
    const { t } = this.props;
    const {
      departments,
      lines,
      units,
      teams,
      myteams,
      routes,
      myroutes,
      rdgEntryType,
      rdgGranularity,
      rdgTimeFrame,
      chkRouteDetails,
      chkPlantModelDetails,
      chkQFactor,
      // chkMinimumUptime,
      HSETasks,
      plantModel,
      dtStartTime,
      dtEndTime,
    } = this.state;

    let globalAccessLevel = getUserRole();

    return (
      <React.Fragment>
        <div className={styles.filterContent}>
          <div>
            <Panel
              id="pnlComplianceSelectionType"
              title={`1. ${t("Report Entry Point")}`}
              borderTop={false}
              borderBottom={false}
              paddingTop={0}
              paddingBottom={0}
              collapsible={false}
            >
              <label>{t("Selection Type")}</label>
              <RadioGroup
                items={[
                  {
                    text: t("Plant Model"),
                    value: "Plant Model",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("My Teams"),
                    value: "My Teams",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("Teams Selection"),
                    value: "Teams Selection",
                    globalAccessLevel: [3, 4],
                  },
                  {
                    text: t("My Routes"),
                    value: "My Routes",
                    globalAccessLevel: [1, 2, 3, 4],
                  },
                  {
                    text: t("Routes Selection"),
                    value: "Routes Selection",
                    globalAccessLevel: [3, 4],
                  },
                ].filter((item) =>
                  item.globalAccessLevel.includes(globalAccessLevel)
                )}
                valueExpr="value"
                displayExpr="text"
                value={rdgEntryType}
                onValueChanged={this.handlerRgdEntryType}
              />
              <label>{t("Q-Factor")}</label>
              <CheckBox
                id="chkQFactor"
                tag="chkQFactor"
                text={t("Q-Factor Tasks Only")}
                value={chkQFactor}
                onValueChanged={this.handlerCheckBox}
              />
              <br />
              <label>{t("HSE Tasks")}</label>
              <CheckBox
                id="HSETasks"
                tag="HSETasks"
                text={t("HSE Tasks Only")}
                value={HSETasks}
                onValueChanged={this.handlerCheckBox}
              />
              {/* <br/>
              <label>{t("Minimum uptime tasks")}</label>
              <CheckBox
                id="chkMinimumUptime"
                tag="chkMinimumUptime"
                text={t("Minimum uptime tasks")}
                value={chkMinimumUptime}
                onValueChanged={this.handlerCheckBox}
              /> */}
            </Panel>
          </div>

          <div>
            {rdgEntryType === "Plant Model" && (
              <Panel
                id="pnlCompliancePlantModelSelection"
                title={`2. ${t("Plant Model Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Granularity")}</label>
                <RadioGroup
                  items={[
                    { text: t("Site"), value: GRANULARITY.Site },
                    { text: t("Department"), value: GRANULARITY.Department },
                    { text: t("Line"), value: GRANULARITY.Line },
                    { text: t("Primary Unit"), value: GRANULARITY.MasterUnit },
                  ]}
                  valueExpr="value"
                  displayExpr="text"
                  value={rdgGranularity}
                  onValueChanged={this.handlerRgdGranularity}
                />
                <div>
                  <label>{t("Selection Filter")}</label>
                  <div className={styles.plantModelSelection}>
                    <SelectBox
                      id="sboDepartmentsCompliance"
                      text={t("Department")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={departments}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.departments}
                      onChange={(values) =>
                        this.handlerSelectBox("departments", values)
                      }
                      labelKey="DeptDesc"
                      valueKey="DeptId"
                      isLoading={false}
                      isDisable={rdgGranularity === GRANULARITY.Site}
                      // visible={rdgGranularity !== GRANULARITY.Site}
                    />
                    <SelectBox
                      id="sboLinesCompliance"
                      text={t("Line")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={lines}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.lines}
                      onChange={(values) =>
                        this.handlerSelectBox("lines", values)
                      }
                      labelKey="LineDesc"
                      valueKey="LineId"
                      isLoading={false}
                      isDisable={
                        rdgGranularity === GRANULARITY.Site ||
                        rdgGranularity === GRANULARITY.Department
                      }
                      // visible={
                      //   rdgGranularity === GRANULARITY.Line ||
                      //   rdgGranularity === GRANULARITY.MasterUnit
                      // }
                    />
                    <SelectBox
                      id="sboUnitsCompliance"
                      text={t("Primary Unit")}
                      enableSelectAll={false}
                      enableClear={false}
                      store={units}
                      isMultiple={false}
                      className={styles.selectBoxPM}
                      value={plantModel.units}
                      onChange={(values) =>
                        this.handlerSelectBox("units", values)
                      }
                      labelKey="MasterDesc"
                      valueKey="MasterId"
                      isLoading={false}
                      isDisable={rdgGranularity !== GRANULARITY.MasterUnit}
                      // visible={rdgGranularity === GRANULARITY.MasterUnit}
                    />
                  </div>
                </div>
              </Panel>
            )}

            {rdgEntryType === "My Teams" && (
              <Panel
                id="pnlComplianceMyTeams"
                title={`2. ${t("My Teams")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Team Details")}</label>
                <CheckBox
                  id="chkRouteDetails"
                  tag="chkRouteDetails"
                  text={t("Route Details")}
                  value={chkRouteDetails}
                  onValueChanged={this.handlerCheckBoxTeams}
                />
                <CheckBox
                  id="chkPlantModelDetails"
                  tag="chkPlantModelDetails"
                  text={t("Plant Model Details")}
                  value={chkPlantModelDetails}
                  onValueChanged={this.handlerCheckBoxTeams}
                />
                <div className={styles.plantModelSelection}>
                  {this.state.loading.myteams && (
                    <>
                      {myteams.length !== 0 ? (
                        <SelectBox
                          id="sboMyTeams"
                          enableSelectAll={true}
                          enableClear={true}
                          store={myteams}
                          isMultiple={true}
                          className={styles.selectBoxPM}
                          value={plantModel.myteams}
                          onChange={(values) =>
                            this.handlerSelectBox("myteams", values)
                          }
                          labelKey="TeamDesc"
                          valueKey="TeamId"
                          isLoading={false}
                          isDisable={false}
                        />
                      ) : (
                        <div className={styles.validationMessage}>
                          <Icon name="warning" />
                          <span>
                            {t("You are not associated to any Team.")}
                          </span>
                        </div>
                      )}
                    </>
                  )}
                </div>
              </Panel>
            )}

            {rdgEntryType === "Teams Selection" && (
              <Panel
                id="pnlComplianceTeamsSelection"
                title={`2. ${t("Teams Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <label>{t("Team Details")}</label>
                <CheckBox
                  id="chkTeamDetails"
                  tag="chkRouteDetails"
                  text={t("Route Details")}
                  value={chkRouteDetails}
                  onValueChanged={this.handlerCheckBoxTeams}
                />
                <CheckBox
                  id="chkPlantModelDetails"
                  tag="chkPlantModelDetails"
                  text={t("Plant Model Details")}
                  value={chkPlantModelDetails}
                  onValueChanged={this.handlerCheckBoxTeams}
                />
                <div className={styles.plantModelSelection}>
                  <SelectBox
                    id="sboTeams"
                    enableSelectAll={true}
                    enableClear={true}
                    store={teams}
                    isMultiple={true}
                    className={styles.selectBoxPM}
                    value={plantModel.teams}
                    onChange={(values) =>
                      this.handlerSelectBox("teams", values)
                    }
                    labelKey="TeamDescription"
                    valueKey="TeamId"
                    isLoading={false}
                    isDisable={false}
                  />
                </div>
              </Panel>
            )}

            {rdgEntryType === "My Routes" && (
              <Panel
                id="pnlComplianceMyRoutes"
                title={`2. ${t("My Routes")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <div className={styles.plantModelSelection}>
                  {this.state.loading.myroutes && (
                    <>
                      {myroutes.length !== 0 ? (
                        <SelectBox
                          id="sboMyRoutes"
                          enableSelectAll={true}
                          enableClear={true}
                          store={myroutes}
                          isMultiple={true}
                          className={styles.selectBoxPM}
                          value={plantModel.myroutes}
                          onChange={(values) =>
                            this.handlerSelectBox("myroutes", values)
                          }
                          labelKey="RouteDesc"
                          valueKey="RouteId"
                          isLoading={false}
                          isDisable={false}
                        />
                      ) : (
                        <div className={styles.validationMessage}>
                          <Icon name="warning" />
                          <span>
                            {t("You are not associated to any Route.")}
                          </span>
                        </div>
                      )}
                    </>
                  )}
                </div>
              </Panel>
            )}

            {rdgEntryType === "Routes Selection" && (
              <Panel
                id="pnlComplianceRoutesSelection"
                title={`2. ${t("Routes Selection")}`}
                borderTop={false}
                borderBottom={false}
                paddingTop={0}
                paddingBottom={0}
                collapsible={false}
              >
                <div>
                  <div className={styles.plantModelSelection}>
                    <SelectBox
                      id="sboRoutes"
                      enableSelectAll={true}
                      enableClear={true}
                      store={routes}
                      isMultiple={true}
                      className={styles.selectBoxPM}
                      value={plantModel.routes}
                      onChange={(values) =>
                        this.handlerSelectBox("routes", values)
                      }
                      labelKey="RouteDescription"
                      valueKey="RouteId"
                      isLoading={false}
                      isDisable={false}
                    />
                  </div>
                </div>
              </Panel>
            )}
          </div>

          <div>
            <Panel
              id="pnlCompliancePeriodSelection"
              title={`3. ${t("Period Selection")}`}
              borderTop={false}
              borderBottom={false}
              paddingTop={0}
              paddingBottom={0}
              collapsible={false}
            >
              <label>{t("Time Frame")}</label>
              <RadioGroup
                items={[
                  { text: t("Yesterday"), value: CUSTOM_PERIOD.Yesterday },
                  { text: t("Today"), value: CUSTOM_PERIOD.Today },
                  { text: t("Last Week"), value: CUSTOM_PERIOD.LastWeek },
                  { text: t("This Week"), value: CUSTOM_PERIOD.ThisWeek },
                  { text: t("Last Month"), value: CUSTOM_PERIOD.LastMonth },
                  { text: t("This Month"), value: CUSTOM_PERIOD.ThisMonth },
                  { text: t("Last 30 Days"), value: CUSTOM_PERIOD.Last30Days },
                  { text: t("User-Defined"), value: CUSTOM_PERIOD.UserDefined },
                ]}
                valueExpr="value"
                displayExpr="text"
                value={rdgTimeFrame}
                onValueChanged={this.handlerRgdTimeFrame}
              />

              {rdgTimeFrame === CUSTOM_PERIOD.UserDefined && (
                <div>
                  <label>{t("Start Time")}</label>
                  <DateTime
                    type="datetime"
                    displayFormat="yyyy-MM-dd hh:mm aa"
                    value={dtStartTime}
                    onValueChanged={(e) =>
                      this.handleInputDate(e, "dtStartTime")
                    }
                    max={dtEndTime}
                  />
                  <label>{t("End Time")}</label>
                  <DateTime
                    type="datetime"
                    displayFormat="yyyy-MM-dd hh:mm aa"
                    value={dtEndTime}
                    onValueChanged={(e) => this.handleInputDate(e, "dtEndTime")}
                    min={dtStartTime}
                  />
                </div>
              )}
            </Panel>
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default Filters;
