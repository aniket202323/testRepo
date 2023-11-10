import axios from "axios";
import decode from "jwt-decode";
import { baseURL } from "../../package.json";
import i18next from "i18next";
import { languages } from "../utils";

axios.interceptors.request.use((config) => {
  if (getToken()) refreshHeaderToken();
  return config;
});

async function login(username, password) {
  return axios({
    method: "post",
    url: baseURL + "api/user/authenticate",
    withCredentials: true,
    data: {
      UserName: username,
      Password: btoa(password),
    },
  })
    .then((response) => {
      i18next.changeLanguage(languages[response.data.LanguageId ?? "en"]);
      setUser(response.data);
    })
    .catch((error) => {
      throw error;
    });
}

async function autologin(token = undefined) {
  let url = token
    ? baseURL + "api/user/opshubautologin"
    : baseURL + "api/user/autologin";

  return axios({
    method: token ? "POST" : "GET",
    withCredentials: true,
    url,
    data: {
      jwtToken: token,
    },
  })
    .then((response) => {
      if (response.data !== null) {
        i18next.changeLanguage(languages[response.data.LanguageId ?? "en"]);
        setUser(response.data);
        return true;
      } else return false;
    })
    .catch((error) => {
      throw error;
    });
}

function logout() {
  sessionStorage.loggedout = true;

  sessionStorage.removeItem("ecil_token");
  sessionStorage.removeItem("user_profile");
  sessionStorage.removeItem("OpsHubData");
  sessionStorage.removeItem("OpsHubPage");
  sessionStorage.removeItem("OpsHubToken");
}

function loggedIn() {
  const token = getToken();
  setAuthorizationHeader(token);
  return !!token && !isTokenExpired(token);
}

function autoLoggedIn() {
  return (sessionStorage.getItem("autologin") ?? "false") === "false"
    ? false
    : true;
}

function getProfile() {
  if (loggedIn()) {
    return JSON.parse(sessionStorage.getItem("user_profile"));
  } else return {};
}

function getUserRole() {
  try {
    const token = getToken();
    const decoded = decode(token);

    let role = parseInt(decoded.role) || -1;

    if (role < 0) {
      sessionStorage.removeItem("ecil_token");
      sessionStorage.removeItem("user_profile");
      window.location.reload();
    }

    return role;
  } catch (error) {
    return -1;
  }
}

function getUserId() {
  try {
    const token = getToken();
    const decoded = decode(token);

    return parseInt(decoded.unique_name) || -1;
  } catch (error) {
    return -1;
  }
}

function hasAuthorizationHeader() {
  return !!axios.defaults.headers.common["AuthToken"];
}

function setAuthorizationHeader(token) {
  if (!hasAuthorizationHeader() && !!token && !isTokenExpired(token)) {
    axios.defaults.headers.common["AuthToken"] = token;
  }
}

function refreshHeaderToken() {
  axios.defaults.headers.common["AuthToken"] = getToken();
}

function getToken() {
  return sessionStorage.getItem("ecil_token");
}

function setUser(data) {
  let profile = Object.assign({}, data);
  delete profile.Token;
  delete profile.Password;

  // window.$userProfile = profile;

  sessionStorage.setItem("ecil_token", data.Token);
  sessionStorage.setItem("user_profile", JSON.stringify(profile));
}

function isTokenExpired(token) {
  try {
    const decoded = decode(token);
    return decoded.exp < Date.now() / 1000;
  } catch (err) {
    return true;
  }
}

export {
  login,
  autologin,
  logout,
  loggedIn,
  autoLoggedIn,
  getProfile,
  getUserRole,
  getUserId,
};
