import React, { Component, memo } from "react";
import ErrorConnection from "./components/ErrorConnection";
import Notification from "./components/Notification";
import Login from "./views/Login";
import Main from "./views/Main";
import PrivateRoute from "./components/PrivateRoute";
import { logAppVersion } from "./utils/index";
import { translate } from "react-i18next";
import { subscribeNotification } from "./services/notification";
import { HashRouter as Router, Switch, Route } from "react-router-dom";

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      errorConnection: false,
      messageScreen: {
        text: "",
        show: false,
      },
      loading: { isLoading: false },
      notification: {
        type: "error",
        icon: "star",
        message: "",
        position: "",
        title: "",
        closable: true,
        show: false,
      },
      secondNotification: {
        type: "error",
        icon: "star",
        message: "",
        position: "",
        title: "",
        closable: true,
        show: false,
      },
      isLoadingFromIframe: false,
      opsHubToken: null,
    };
  }

  componentDidMount = () => {
    logAppVersion();
    let secondsWaitForOpshub = 4;

    if (window.location !== window.parent.location)
      this.setState({ isLoadingFromIframe: true });

    window.onmessage = (e) => {
      console.log("eCIL APP-Message | ", e.data);
      let { id, OpsHubPage, token } = e.data;
      if (OpsHubPage && token && id === "pg-response") {
        if (sessionStorage.getItem("OpsHubPage") !== OpsHubPage) {
          sessionStorage.setItem("OpsHubPage", OpsHubPage);
          sessionStorage.setItem("OpsHubToken", token);
        }
        this.setState({
          isLoadingFromIframe: false,
          opsHubToken: token,
        });
      }
    };

    setTimeout(() => {
      this.state.isLoadingFromIframe &&
        this.setState({
          isLoadingFromIframe: false,
        });
    }, secondsWaitForOpshub * 1000);

    window.addEventListener("online", this.setOnlineStatus);
    window.addEventListener("offline", this.setOnlineStatus);

    subscribeNotification().subscribe((notification) => {
      let isSecondNotification = notification?.isSecondNotification || false;
      if (!isSecondNotification)
        this.setState({
          notification,
          secondNotification: { show: false },
        });
      else
        this.setState({
          secondNotification: notification,
        });
    });
  };

  setOnlineStatus = () => {
    this.setState({ errorConnection: !this.state.errorConnection });
  };

  render = () => {
    const {
      notification,
      errorConnection,
      secondNotification,
      isLoadingFromIframe,
      opsHubToken,
    } = this.state;
    const { t } = this.props;

    return (
      <React.Fragment>
        <ErrorConnection display={errorConnection} />
        <Notification
          show={notification.show}
          icon={notification.icon}
          type={notification.type}
          position={notification.position}
          closable={notification.closable}
          title={notification.title}
          message={notification.message}
        />
        {secondNotification?.show && notification.show && (
          <Notification
            show={secondNotification.show}
            icon={secondNotification.icon}
            type={secondNotification.type}
            position={"below"}
            closable={secondNotification.closable}
            title={secondNotification.title}
            message={secondNotification.message}
          />
        )}
        <Router>
          {isLoadingFromIframe ? (
            <span>...Loading from OpsHub iFrame</span>
          ) : (
            <Switch>
              <Route
                exact
                path="/login"
                render={(props) => (
                  <Login {...props} t={t} opsHubToken={opsHubToken} />
                )}
              />
              <PrivateRoute exact path="/" component={Main} translation={t} />
            </Switch>
          )}
        </Router>
      </React.Fragment>
    );
  };
}

export default translate()(memo(App));
