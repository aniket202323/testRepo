import { createStore, combineReducers } from "redux";
import { composeWithDevTools } from "redux-devtools-extension";
import { applyMiddleware } from "redux";
import thunk from "redux-thunk";
import settings from "./ducks/settings";

export default createStore(
  combineReducers({
    settings,
  }),
  composeWithDevTools(applyMiddleware(thunk))
);
