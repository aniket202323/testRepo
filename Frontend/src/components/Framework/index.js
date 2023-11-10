import React, { PureComponent, memo } from "react";
import TopBar, {
  TopBarLeft,
  TopBarButton,
  TopBarRight,
  TopBarCenter,
} from "./TopBar";
import LeftBar from "./LeftBar";
import Preload from "./Preload";
import Breadcrumb from "./Breadcrumb";
import { getProfile, logout } from "../../services/auth";
import {
  getDBServerName,
  getSiteLang,
  getSiteParamSpecSetting,
} from "../../services/application";
import { connect } from "react-redux";
import { bindActionCreators } from "redux";
import { updateSettings } from "../../redux/ducks/settings";
import { setBreadcrumbEvents } from "./Breadcrumb/events";
import { isTablet } from "../../utils/index";
import logo from "../../resources/ecil-logo-white.png";
import { version } from "../../../package.json";
import { VIEW } from "../../utils/constants";
import { confirm } from "devextreme/ui/dialog";
import Icon from "../Icon";
import styles from "./styles.module.scss";

class Framework extends PureComponent {
  constructor(props) {
    super(props);

    this.contentRef = React.createRef();
    this.handleLeftbarOutsideClick = this.handleLeftbarOutsideClick.bind(this);

    this.state = {
      site: "",
      lang: "",
      showFilters: true,
      navigationItems: [
        {
          text: "Tasks Selection",
          accesLevel: [4, 3, 2, 1],
          items: [
            {
              text: VIEW.TASK_SELECTION.PlantModel,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.TASK_SELECTION.MyTeams,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.TASK_SELECTION.Teams,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.TASK_SELECTION.MyRoutes,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.TASK_SELECTION.Routes,
              accesLevel: [4, 3],
            },
          ],
        },
        !isTablet() && {
          text: "Reports",
          accesLevel: [4, 3, 2, 1],
          items: [
            {
              text: VIEW.REPORT.ComplianceRpt,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.REPORT.EmagRpt,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.REPORT.TasksPlanningRpt,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.REPORT.MultipleAssignmentsTasksRpt,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.REPORT.TasksConfigurationRpt,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.REPORT.UnassignedTasksRpt,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.REPORT.SchedulingErrorsRpt,
              accesLevel: [4, 3],
            },
          ],
        },
        isTablet() && {
          text: "Reports",
          accesLevel: [4, 3, 2, 1],
          items: [
            {
              text: VIEW.REPORT.ComplianceRpt,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.REPORT.EmagRpt,
              accesLevel: [4, 3, 2, 1],
            },
            {
              text: VIEW.REPORT.TasksPlanningRpt,
              accesLevel: [4, 3, 2, 1],
            },
          ],
        },
        !isTablet() && {
          text: "Administration",
          accesLevel: [4, 3],
          items: [
            {
              text: VIEW.ADMINISTRATION.RoutesMgmt,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.ADMINISTRATION.TeamsMgmt,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.ADMINISTRATION.TasksMgmt,
              accesLevel: [4],
            },
            {
              text: VIEW.ADMINISTRATION.VersionMgmt,
              accesLevel: [4],
            },
            {
              text: VIEW.ADMINISTRATION.QrCodeByTask,
              accesLevel: [4, 3],
            },
            {
              text: VIEW.ADMINISTRATION.QrCodeByRoute,
              accesLevel: [4, 3],
            },
          ],
        },
      ].filter((x) => x !== false),
    };
  }

  componentDidMount() {
    Promise.all([
      getDBServerName(),
      getSiteLang(),
      getSiteParamSpecSetting(),
    ]).then((response) => {
      const [serverName, serverLang, paramSpecSetting] = response;
      this.setState({ site: serverName, lang: serverLang }, () => {
        localStorage.setItem("siteLng", serverLang);
        localStorage.setItem("paramSpecSetting", paramSpecSetting);
      });
    });

    let defaultTitle = "eCIL";
    let compliancePrint = "CompliancePrintingXtraReport";

    // set print title for CIL Result Report
    window.onafterprint = (e) => (document.title = defaultTitle);
    window.onbeforeprint = (e) => {
      let view = this.props.settings.navbar.itemSelected;
      if (view === "CIL Results Report") document.title = compliancePrint;
      else document.title = defaultTitle;
    };

    //handle left bar click outside
    if (isTablet()) {
      document.addEventListener("mousedown", this.handleLeftbarOutsideClick);
    }

    this.handleNavigationItem("My Routes");
  }

  componentWillUnmount = () => {
    if (isTablet())
      document.removeEventListener("mousedown", this.handleLeftbarOutsideClick);
  };

  handleLeftbarOutsideClick(event) {
    if (this.contentRef && this.contentRef.current.contains(event.target)) {
      if (this.props.settings.navbar.opened)
        this.props.updateSettings({ navbar: { opened: false } });
    }
  }

  getNavigationGroup = (itemSelected) => {
    var parent = "";

    this.state.navigationItems.forEach((item) => {
      if (item.items)
        item.items.forEach((subitems) => {
          if (subitems.text === itemSelected) parent = item.text;
        });
    });
    return parent;
  };

  handleLogout = () => {
    logout();
    window.location.reload();
  };

  handleNavigation = () => {
    this.props.updateSettings({
      navbar: { opened: !this.props.settings.navbar.opened },
    });
  };

  handleNavigationItem = (item) => {
    let previusItemSelected = this.props.settings.navbar.itemSelected;
    if (previusItemSelected !== item)
      if (
        previusItemSelected === "Routes Management" &&
        localStorage.getItem("hasUpdates") === "true"
      ) {
        let dialog = confirm(
          `<span>You have changes without save, do you want to continue without saving?</span>`,
          "Unsaved changes"
        );
        dialog.then((dialogResult) => {
          if (dialogResult) {
            setBreadcrumbEvents(null);
            localStorage.removeItem("hasUpdates");
            this.props.updateSettings({
              navbar: {
                opened: false,
                group: this.getNavigationGroup(item),
                itemSelected: item,
              },
            });
          } else {
            setBreadcrumbEvents(null);
            this.props.updateSettings({
              navbar: {
                opened: false,
                group: this.getNavigationGroup(previusItemSelected),
                itemSelected: previusItemSelected,
              },
            });
          }
        });
      } else {
        localStorage.removeItem("hasUpdates");
        setBreadcrumbEvents(null);
        this.props.updateSettings({
          navbar: {
            opened: false,
            group: this.getNavigationGroup(item),
            itemSelected: item,
          },
        });
      }
  };

  // handlerInfo = () => {
  //   setBreadcrumbEvents(null);
  //   var inAbout = this.props.settings.navbar.group === "About eCIL";

  //   if (inAbout) {
  //     this.props.updateSettings({
  //       navbar: {
  //         opened: false,
  //         group: "Tasks Selection",
  //         itemSelected: "Plant Model",
  //       },
  //     });
  //   } else {
  //     this.props.updateSettings({
  //       navbar: {
  //         opened: false,
  //         group: "About eCIL",
  //         itemSelected: "Current Version " + version,
  //       },
  //     });
  //   }
  // };

  render() {
    const { t, children } = this.props;
    const { site, navigationItems } = this.state;
    const { navbar } = this.props.settings;

    const profile = getProfile();

    return (
      <div className={styles.root}>
        <div
          id="top-bar"
          style={{
            display:
              sessionStorage.getItem("OpsHubPage") === "MyRoutes"
                ? "none"
                : "contents",
          }}
        >
          <TopBar>
            <TopBarLeft>
              <div className={`${styles["logo-container"]}`}>
                <img src={logo} alt="PG" className={styles.logo} />
              </div>
              <div className={styles.header}>
                <TopBarButton
                  id="btnShowHideLeftMenu"
                  icon="bars"
                  className={styles.leftBarButton}
                  onClick={this.handleNavigation}
                />
                <h2 className={`${styles["showMax1024"]} ${styles.site}`}>
                  {site}
                </h2>
              </div>
            </TopBarLeft>
            <TopBarCenter>
              <div className={styles.centerTopBar}>
                <h3>
                  <span>{process.env.REACT_APP_REPORT_NAME}</span>
                </h3>
                <span>{"v" + version.slice(0, 3)}</span>
              </div>
            </TopBarCenter>
            <TopBarRight>
              <div
                className={`${styles["showMax1024"]} ${styles["right-info"]} `}
              >
                <span className={styles.timeout}>
                  <Icon name="clock-o" primary style={{ margin: "7.5px" }} />
                  {t("Session Timeout")}:{" "}
                  <span id="sessionTimeout">{profile?.SessionTimeout}</span>
                  &nbsp;min
                </span>
              </div>
              <div className={`${styles["right-info"]} `}>
                <span className={styles.username}>
                  <Icon name="user" primary style={{ margin: "7.5px" }} />
                  {profile ? profile.UserName : ""}
                </span>
              </div>
              <TopBarButton
                id="btnSignOut"
                icon="sign-out"
                onClick={this.handleLogout}
              />
            </TopBarRight>
          </TopBar>
        </div>
        <Preload t={t} />
        <div className={styles.main}>
          <LeftBar
            t={t}
            open={navbar.opened}
            selectedItem={navbar.itemSelected}
            onClick={this.handleNavigationItem}
            items={navigationItems}
          />
          <div ref={this.contentRef} className={styles.mainContent}>
            <Breadcrumb
              route={`eCIL|${t(navbar.group)}|${t(navbar.itemSelected)}`}
            />
            {children}
          </div>
        </div>
      </div>
    );
  }
}

const mapStateToProps = ({ settings }) => {
  return { settings };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators({ updateSettings }, dispatch);
};

export default memo(connect(mapStateToProps, mapDispatchToProps)(Framework));
