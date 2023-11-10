import React, { PureComponent, memo } from "react";
import Framework from "../../components/Framework";
import TasksSelection from "./TasksSelection";
import RoutesManagement from "./Administration/RoutesManagement";
import TeamsManagement from "./Administration/TeamsManagement";
import TasksManagement from "./Administration/TasksManagement";
import VersionManagement from "./Administration/VersionManagement";
import Compliance from "./Reports/Compliance";
import Emag from "./Reports/Emag";
import TasksPlanning from "./Reports/TasksPlanning";
import MultipleAssignments from "./Reports/MultipleAssignments";
import UnassignedTasks from "./Reports/UnassignedTasks";
import TasksConfiguration from "./Reports/TasksConfiguration";
import SchedulingErrors from "./Reports/SchedulingErrors";
// import About from "./About";
import QrCode from "./QRCode";
import { connect } from "react-redux";
import { bindActionCreators } from "redux";
import { updateSettings } from "../../redux/ducks/settings";
import { getProfile, logout } from "./../../services/auth";
import { VIEW } from "../../utils/constants";
import queryString from "query-string";

class Main extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      timeout: 1000 * 60 * 20,
    };
  }

  componentDidMount = () => {
    this.sessionTimeout = null;
    this.timer();

    //Timer by events
    window.addEventListener("touchstart", this.timer, false);
    window.addEventListener("mousedown", this.timer, false);
    window.addEventListener("keypress", this.timer, false);

    //Include fonts to export in different languages
    // Promise.all([
    //   import("../../utils/pdf/arimo-regular.js"),
    //   import("../../utils/pdf/simsun-normal.js"),
    //   import("../../utils/pdf/trado-normal.js"),
    // ]).then(() => {
    //   document
    //     .getElementById("root")
    //     .setAttribute("data-pdf-font-ready", "true");
    // });
  };

  componentWillUnmount() {
    clearInterval(this.sessionTimeout);
  }

  timer = () => {
    var profileTimeout = getProfile()?.SessionTimeout;
    this.timeout = profileTimeout;

    let elem = document.getElementById("sessionTimeout");
    if (elem) elem.innerHTML = this.timeout;

    clearInterval(this.sessionTimeout);
    this.sessionTimeout = setInterval(() => {
      let elem = document.getElementById("sessionTimeout");
      this.timeout -= 1;

      if (elem) elem.innerHTML = this.timeout;
      if (this.timeout === 0) {
        logout();
        window.location.reload();
      }
    }, 60000); //each 1 minute (60000)
  };

  render = () => {
    const { t } = this.props;
    const { navbar } = this.props.settings;

    return (
      <React.Fragment>
        <Framework t={t} handleFilter={this.handleFilter}>
          {(() => {
            if (navbar.group === "Tasks Selection") {
              return (
                <TasksSelection
                  t={t}
                  viewActive={navbar.itemSelected}
                  updateSettings={this.props.updateSettings}
                  urlParams={queryString.parse(window.location.search)}
                />
              );
            }

            if (navbar.group === "Reports") {
              switch (navbar.itemSelected) {
                case VIEW.REPORT.ComplianceRpt:
                  return <Compliance t={t} />;
                case VIEW.REPORT.EmagRpt:
                  return <Emag t={t} />;
                case VIEW.REPORT.TasksPlanningRpt:
                  return <TasksPlanning t={t} />;
                case VIEW.REPORT.MultipleAssignmentsTasksRpt:
                  return <MultipleAssignments t={t} />;
                case VIEW.REPORT.TasksConfigurationRpt:
                  return <TasksConfiguration t={t} />;
                case VIEW.REPORT.UnassignedTasksRpt:
                  return <UnassignedTasks t={t} />;
                case VIEW.REPORT.SchedulingErrorsRpt:
                  return <SchedulingErrors t={t} />;
                default:
                  break;
              }
            }

            if (navbar.group === "Administration") {
              switch (navbar.itemSelected) {
                case VIEW.ADMINISTRATION.RoutesMgmt:
                  return <RoutesManagement t={t} />;
                case VIEW.ADMINISTRATION.TeamsMgmt:
                  return <TeamsManagement t={t} />;
                case VIEW.ADMINISTRATION.TasksMgmt:
                  return <TasksManagement t={t} />;
                case VIEW.ADMINISTRATION.VersionMgmt:
                  return <VersionManagement t={t} />;
                case VIEW.ADMINISTRATION.QrCodeByTask:
                  return <QrCode t={t} by={"byTask"} />;
                case VIEW.ADMINISTRATION.QrCodeByRoute:
                  return <QrCode t={t} by={"byRoute"} />;
                default:
                  break;
              }
            }

            // if (navbar.group === "About eCIL") {
            //   return <About />;
            // }
          })()}
        </Framework>
      </React.Fragment>
    );
  };
}

const mapStateToProps = ({ settings }) => {
  return { settings };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators({ updateSettings }, dispatch);
};

export default memo(connect(mapStateToProps, mapDispatchToProps)(Main));
