import React, { PureComponent } from "react";
import SelectBox from "../../../../components/SelectBox";
import {
  getLines,
  getUnits,
  getWorkcells,
} from "../../../../services/plantModel";
import { getAllTeams, getMyTeams } from "../../../../services/teams";
import {
  getAllRoutes,
  getMyRoutes,
  findRouteId,
} from "../../../../services/routes";
import { getURLInfoByQRId } from "../../../../services/qrcodes";
import { entriesCompare } from "../../../../utils";
import { updatePlantModelView } from "../options";
import styles from "../styles.module.scss";

const initialState = {
  lines: [],
  units: [],
  workcells: [],
  teams: [],
  routes: [],
  myteams: [],
  myroutes: [],
  selected: {
    lines: [],
    units: [],
    workcells: [],
    teams: [],
    routes: [],
    myteams: [],
    myroutes: [],
  },
};

class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = { ...initialState, opsHubRouteId: [] };
  }

  componentDidMount = () => {
    let qrId = this.props.urlParams?.qrId || "";
    let isRoute = this.props.urlParams?.isRoute || "";
    let TourStopIds = this.props.urlParams?.tourStopId || "";
    let byRouteId = this.props.urlParams?.myroute;
    if (qrId && isRoute.includes("false")) {
      this.setFiltersByURL(isRoute);
    } else if (this.props.viewActive === "Plant Model") {
      getLines().then((response) =>
        this.setState({
          lines: response,
        })
      );
    }

    if (this.props.viewActive === "My Teams") {
      getMyTeams().then((response) =>
        this.setState({
          myteams: response,
        })
      );
    }

    if (this.props.viewActive === "Teams") {
      getAllTeams().then((response) =>
        this.setState({
          teams: response,
        })
      );
    }
    if (qrId && isRoute.includes("true")) {
      this.setFiltersByURL(isRoute);
    } else if (this.props.viewActive === "My Routes" || byRouteId) {
      getMyRoutes().then((response) => {
        if (!byRouteId)
          this.setState({
            myroutes: response,
          });
        else {
          let qrCodeNotFound = !response.some(
            (x) => x.RouteId === parseInt(byRouteId)
          );
          this.setState(
            {
              routes: response,
              selected: {
                ...this.state.selected,
                myroutes: qrCodeNotFound ? [] : [parseInt(byRouteId)],
              },
            },
            () =>
              this.props.handlerDataByQr(TourStopIds || null, qrCodeNotFound)
          );
        }
      });
    }

    if (this.props.viewActive === "Routes") {
      getAllRoutes().then((response) => {
        this.setState({
          routes: response,
        });
      });
    }
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (this.props.viewActive === "Plant Model") {
      const { lines, units } = this.state.selected;
      const { lines: prevLines, units: prevUnits } = prevState.selected;

      if (prevProps.viewActive !== this.props.viewActive) {
        getLines().then((response) =>
          this.setState({
            lines: response,
          })
        );
      }

      if (prevLines !== lines && lines.length > 0) {
        getUnits(lines.join(",")).then((response) => {
          if (this.state.selected.lines.length > 0)
            this.setState({ units: response });
        });
      }

      if (prevUnits !== units && units.length > 0) {
        getWorkcells(units.join(",")).then((response) => {
          if (this.state.selected.units.length > 0)
            this.setState({ workcells: response });
        });
      }
    }

    if (
      prevProps.viewActive !== this.props.viewActive &&
      this.props.viewActive === "My Teams"
    ) {
      getMyTeams().then((response) =>
        this.setState({
          myteams: response,
        })
      );
    }

    if (
      prevProps.viewActive !== this.props.viewActive &&
      this.props.viewActive === "Teams"
    ) {
      getAllTeams().then((response) =>
        this.setState({
          teams: response,
        })
      );
    }

    if (
      prevProps.viewActive !== this.props.viewActive &&
      this.props.viewActive === "My Routes"
    ) {
      getMyRoutes().then((routesAssociated) => {
        let routesAssociatedIds = routesAssociated?.map((r) => r?.RouteId);
        if (
          routesAssociatedIds?.length === 0 ||
          routesAssociatedIds?.length > 1
        ) {
          this.setState(
            {
              myroutes: routesAssociated,
            },
            () => {
              if (!prevState.opsHubRouteId.length) this.getOpsHubData();
            }
          );
        } else if (routesAssociatedIds?.length === 1) {
          this.setState(
            {
              myroutes: routesAssociated,
              selected: {
                ...this.state.selected,
                myroutes: routesAssociatedIds,
              },
            },
            () => this.props.handlerData()
          );
        }
      });
    }

    if (
      prevProps.viewActive !== this.props.viewActive &&
      this.props.viewActive === "Routes"
    ) {
      getAllRoutes().then((response) => {
        this.setState({
          routes: response,
        });
      });
    }
    this.disabledToRun();
  };

  setFiltersByURL = (isRoute) => {
    let qrId = this.props.urlParams?.qrId;
    getURLInfoByQRId(qrId, isRoute.includes("true")).then((response) => {
      if (response?.QrId === 0) {
        // this.props.handlerDataByQr(null, true);
        if (isRoute.includes("false"))
          getLines().then((lines) =>
            this.setState(
              {
                lines,
              },
              () => this.props.handlerDataByQr(null, false)
            )
          );
        return;
      }

      let { Line: urlLines, RouteIdstr, VarId: tasksIds } = response;

      if (isRoute.includes("false")) {
        if (urlLines) {
          Promise.all([getLines(), getUnits(urlLines)]).then((resp) => {
            const [resLines, resUnits] = resp;

            this.setState(
              {
                lines: resLines,
                units: resUnits,
                selected: {
                  ...this.state.selected,
                  lines: urlLines.split(",").map((value) => parseInt(value)),
                },
              },
              () => this.props.handlerDataByQr(tasksIds)
            );
          });

          return;
        }
      } else if (isRoute.includes("true")) {
        getAllRoutes().then((routes) => {
          let routesIds = RouteIdstr?.split(",").map((value) =>
            parseInt(value)
          );
          this.setState(
            {
              routes,
              selected: {
                ...this.state.selected,
                myroutes: routesIds,
              },
            },
            () => {
              this.props.handlerDataByQr(tasksIds);
              routesIds &&
                this.props.addRouteDescInHeader(
                  this.state.routes.find(
                    (r) => r.RouteId === parseInt(routesIds[0])
                  )
                );
            }
          );
        });
      }
    });
  };

  clearState = () => {
    this.setState({ ...initialState });
  };

  handleSelectBox = (key, values) => {
    if (this.props.viewActive === "Plant Model") {
      if (!entriesCompare(values, this.state.selected[key])) {
        this.setState({
          ...this.state,
          ...updatePlantModelView(key, values, this.state),
        });
      }
    } else {
      this.setState({ selected: { ...this.state.selected, [key]: values } });
    }
  };

  disabledToRun = () => {
    let disabled = true;
    let { lines, teams, routes, myteams, myroutes } = this.state.selected;

    lines = lines || [];
    teams = teams || [];
    routes = routes || [];
    myteams = myteams || [];
    myroutes = myroutes || [];

    disabled =
      lines.length !== 0 ||
      teams.length !== 0 ||
      routes.length !== 0 ||
      myteams.length !== 0 ||
      myroutes.length !== 0;

    setTimeout(() => {
      let btnRocket = document.getElementById("btnRunTasksSelection");
      let btnRocketMyRoutes = document.getElementById(
        "btnRunTasksSelectionMyRoutes"
      );
      if (btnRocket !== null) btnRocket.disabled = !disabled;
      if (btnRocketMyRoutes !== null) btnRocketMyRoutes.disabled = !disabled;
    }, 100);
  };

  getOpsHubData = () => {
    let opshubData = sessionStorage.getItem("OpsHubData");
    if (opshubData) {
      opshubData = JSON.parse(opshubData);
      let variables = Array.isArray(opshubData.variableInfo)
        ? opshubData.variableInfo[0]?.variables
        : [];
      let Var_Id = Array.isArray(variables) ? variables[0]?.variableId : null;
      if (Var_Id)
        findRouteId(Var_Id).then((response) => {
          this.setState(
            { selected: { myroutes: [response] }, opsHubRouteId: [response] },
            () => {
              this.props.handlerData();
              response &&
                this.props.addRouteDescInHeader(
                  this.state.myroutes.find(
                    (r) => r.RouteId === parseInt(response)
                  )
                );
            }
          );
        });
    }
  };

  render() {
    const { t, viewActive } = this.props;
    const { lines, units, workcells, selected } = this.state;

    let itemKey =
      viewActive !== "Plant Model"
        ? viewActive.toLowerCase().replace(" ", "")
        : viewActive;

    return (
      <div className={styles.multiSelectionGroup}>
        {viewActive === "Plant Model" ? (
          <React.Fragment>
            <SelectBox
              text={t("Production Line")}
              id="sboLinesTasksSelection"
              enableSelectAll={true}
              enableClear={true}
              store={lines}
              isMultiple={true}
              className={styles.selectBox}
              value={selected.lines}
              onChange={(values) => this.handleSelectBox("lines", values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              text={t("Primary Unit")}
              id="sboUnitsTasksSelection"
              enableSelectAll={true}
              enableClear={true}
              store={units}
              isMultiple={true}
              className={styles.selectBox}
              value={selected.units}
              onChange={(values) => this.handleSelectBox("units", values)}
              labelKey="MasterDesc"
              valueKey="MasterId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              text={t("Module")}
              id="sboWorkcellsTasksSelection"
              enableSelectAll={true}
              enableClear={true}
              store={workcells}
              isMultiple={true}
              className={styles.selectBox}
              value={selected.workcells}
              onChange={(values) => this.handleSelectBox("workcells", values)}
              labelKey="SlaveDesc"
              valueKey="SlaveId"
              isLoading={false}
              isDisable={false}
            />
          </React.Fragment>
        ) : (
          <React.Fragment>
            <SelectBox
              text={t(this.props.viewActive)}
              id={itemKey}
              enableSelectAll={viewActive.includes("Route") ? false : true}
              enableClear={true}
              // eslint-disable-next-line no-eval
              store={eval(this.state[itemKey])}
              isMultiple={viewActive.includes("Route") ? false : true}
              className={styles.selectBoxOne}
              value={selected[itemKey]}
              onChange={(values) => this.handleSelectBox(itemKey, values)}
              labelKey={viewActive.includes("Teams") ? "TeamDesc" : "RouteDesc"}
              valueKey={viewActive.includes("Teams") ? "TeamId" : "RouteId"}
              isLoading={false}
              isDisable={false}
            />
          </React.Fragment>
        )}
      </div>
    );
  }
}

export default Filters;
