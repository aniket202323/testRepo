import React, { Component } from "react";
import eCILLogo from "./../../resources/ecil-logo.png";
import { login, autologin, loggedIn } from "../../services/auth";
import Icon from "../../components/Icon";
import Button from "../../components/Button";
import styles from "./styles.module.scss";

class Login extends Component {
  constructor(props) {
    super(props);
    this.state = {
      username: "",
      password: "",
      errorMsg: "",
      loading: false,
      autologin: false,
      opsHubToken: null,
      isLoadingFromOpsHub: false,
    };
  }

  componentDidUpdate = () => {
    if (!loggedIn() && this.props.opsHubToken && !this.state.opsHubToken)
      this.setState(
        {
          opsHubToken: this.props.opsHubToken,
        },
        () => this.autoLogin(this.props.opsHubToken)
      );
    else if (
      !loggedIn() &&
      !sessionStorage.getItem("autologin") &&
      window.location === window.parent.location
    ) {
      this.autoLogin();
    }
  };

  componentDidMount = () => {
    document.title = "Login";

    if (window.location !== window.parent.location)
      this.setState({ autologin: true, isLoadingFromOpsHub: true }, () =>
        this.opsHuAutologinWait()
      );

    if (sessionStorage.loggedout) sessionStorage.removeItem("loggedout");
    else this.sendMessage();

    document
      .querySelector("#txtPassword")
      .addEventListener("keypress", this.handleClick);
  };

  handleClick = (e) => {
    if (e.key === "Enter") document.querySelector("#btnLogIn").click();
  };

  componentWillUnmount() {
    document.title = "eCIL";
    document
      .querySelector("#txtPassword")
      .removeEventListener("keypress", this.handleClick);
  }

  sendMessage = () => {
    if (window.opener) window.opener.postMessage({ handshake: "true" }, "*");
    else window.parent.postMessage({ handshake: "true" }, "*");
  };

  handleClick = (e) => {
    if (e.key === "Enter") document.querySelector("#btnLogIn").click();
  };

  handleInputChange = (event) => {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value,
      errorMsg: "",
    });
  };

  handleLogin = (event) => {
    const { username, password } = this.state;
    const { t, history } = this.props;

    if (username !== "" && password !== "") {
      this.setState({ loading: true, errorMsg: "" }, () => {
        login(username, password)
          .then(() => history.push("/"))
          .catch((error) => {
            this.setState({
              errorMsg:
                error.response?.data ??
                t(
                  `The server encountered an internal error and was unable to complete your request`
                ),
              loading: false,
            });
          });
      });
    } else {
      this.setState({
        errorMsg: t("You need to enter username or password"),
        loading: false,
      });
    }
    event.preventDefault();
  };

  handleAutoLogin = (event) => {
    const { t, history } = this.props;

    this.setState({ loading: true, errorMsg: "" }, () => {
      autologin()
        .then((res) => {
          if (!res)
            this.setState({
              loading: false,
              errorMsg: t("Automatic logon failed."),
            });
          else history.push("/");
        })
        .catch(() => {
          this.setState({
            loading: false,
            errorMsg: t(
              "Sorry, we are unable to authenticate your account at this time. Please submit a ticket to the help desk for assistance with configuring IIS authentication correctly."
            ),
          });
        });
    });

    event.preventDefault();
  };

  autoLogin = (opshubToken = "") => {
    sessionStorage.setItem("autologin", true);

    this.setState({ autologin: true }, () => {
      autologin(opshubToken)
        .then((response) => {
          if (response) {
            this.props.history.push("/");
          }
        })
        .catch(() => {
          this.setState({ autologin: false }, () =>
            sessionStorage.setItem("autologin", true)
          );
        });
    });
  };

  opsHuAutologinWait = () => {
    setTimeout(() => {
      this.setState({ autologin: false });
    }, 8000);
  };

  render() {
    const { t } = this.props;
    const {
      username,
      password,
      errorMsg,
      loading,
      autologin,
      isLoadingFromOpsHub,
    } = this.state;

    return (
      <div className={styles.container}>
        <div className={styles.loginContainer}>
          <form className={styles.loginForm}>
            <img alt="" src={eCILLogo} className={styles.logo} />
            {/* <div style={{ display: isTryingOpsHubLogin ? "none" : "contents" }}> */}
            <div>
              <input
                id="txtUsername"
                type="text"
                name="username"
                placeholder="DomainName\Username"
                value={username}
                onChange={this.handleInputChange}
                className={styles.formControl}
                disabled={loading || autologin}
              />
              <input
                id="txtPassword"
                type="password"
                name="password"
                placeholder="Password"
                value={password}
                onChange={this.handleInputChange}
                className={styles.formControl}
                disabled={loading || autologin}
              />
              <Button
                id="btnLogIn"
                icon="sign-in"
                text={t("Log In")}
                classes={styles.btn + " " + styles.ripple}
                onClick={this.handleLogin}
                disabled={loading || autologin}
                primary
                iconStyle={{ fontSize: "smaller" }}
              />
              <Button
                id="btnAutoLogIn"
                icon="sign-in"
                text={t("Auto Log In")}
                classes={styles.btn + " " + styles.ripple}
                onClick={this.handleAutoLogin}
                disabled={loading || autologin}
                primary
                iconStyle={{ fontSize: "smaller" }}
              />
            </div>
            <div className={styles.message}>
              {loading && (
                <span className={styles.loadingMsg}>
                  <Icon name="refresh" spin={loading} />
                  &nbsp;{t("Loading")}
                </span>
              )}
              {errorMsg !== "" && (
                <span className={styles.errMsg}>{errorMsg}</span>
              )}
              {autologin && !loading && (
                <span className={styles.autologinMsg}>
                  <Icon name="refresh" spin={true} />
                  &nbsp;{t("Trying to login automatically")}
                  {isLoadingFromOpsHub ? " from MyProficy" : ""}...
                </span>
              )}
            </div>
          </form>
        </div>
        <div></div>
      </div>
    );
  }
}

export default Login;
