import React from "react";
import { Redirect, Route } from "react-router-dom";
import { loggedIn } from "../services/auth";

const PrivateRoute = ({ component: Component, translation, urlParams }) => {
  urlParams = Object.keys(urlParams || {}).length > 0 ? urlParams : null;
  return (
    <Route
      render={(props) =>
        loggedIn() ? (
          <Component {...props} t={translation} urlParams={urlParams} />
        ) : (
          <Redirect to={{ pathname: "/login" }} />
        )
      }
    />
  );
};
export default PrivateRoute;
