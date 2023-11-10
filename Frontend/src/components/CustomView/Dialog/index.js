import React, { Component } from "react";
import ViewBox from "./ViewBox";
import Input from "../../../components/Input";
import Button from "../../../components/Button";
import CheckBox from "../../../components/CheckBox";
import { getUserId, getUserRole } from "../../../services/auth";
import {
  getCustomView,
  setSiteDefaultView,
  setUserDefaultView,
  saveCustomView,
  deleteCustomView,
} from "../../../services/customView";
import { warning, error } from "../../../services/notification";
import { entriesCompare } from "../../../utils/index";
import { displayPreload } from "../../Framework/Preload";
import { isTablet } from "../../../utils/index";
import styles from "./styles.module.scss";
import Icon from "../../Icon";

const initialState = {
  openFormView: false,
  currentView: "",
  event: "",
  viewCopy: "",
  selectors: {
    chkPublicView: false,
    chkUserDefaultView: false,
    chkSetUserDefaultView: false,
    chkSetSiteDefaultView: false,
  },
  inputLength: 0,
};

let customViewDialog = null;

const systemsViews = [
  "FL View",
  "Plant Model View",
  "Routes View",
  "Teams View",
  "TourStop View",
  "Team-Route View",
];

class CustomViewDialog extends Component {
  constructor(props) {
    super(props);
    this.state = {
      views: [],
      ...initialState,
    };

    customViewDialog = this;
  }

  componentDidMount = () => {
    this.getViews();
  };

  componentDidUpdate = (prevProps, prevState) => {
    let { currentView } = this.state;
    let isClosing =
      prevState.currentView.ViewDescription === currentView.ViewDescription;
    if (prevProps.opened !== this.props.opened) {
      if (!this.props.opened) {
        setTimeout(() => {
          this.setState({
            ...initialState,
            currentView: this.state.currentView,
            views: this.state.views,
          });
        }, 250);
      }
    }
    if (
      !isTablet() &&
      currentView.ViewDescription?.includes("Tour") &&
      isClosing
    ) {
      this.collapseUnassignedTSGroup();
    }
  };

  shouldComponentUpdate = (nextProps, nextState) => {
    if (
      nextProps.opened !== this.props.opened ||
      !entriesCompare(nextState, this.state)
    ) {
      return true;
    } else return false;
  };

  getViews = () => {
    displayPreload(true);
    getCustomView(this.props.viewName).then((response) => {
      let currentView =
        response?.find((view) => view.IsUserDefault) ??
        response?.find((view) => view.IsSiteDefault) ??
        "";

      if (currentView.ViewDescription?.includes("Tour") && !isTablet()) {
        let data = JSON.parse(currentView.Data);
        let TourDesc = data?.columns?.find((c) => c.dataField === "TourDesc");
        TourDesc.filterOperations = ["<>"];
        TourDesc.filterValues = [""];
        TourDesc.filterType = "exclude";
        currentView.Data = JSON.stringify(data);
      }

      this.setState({ views: response, currentView }, () => {
        isTablet() &&
          currentView &&
          this.props.applyCustomView(JSON.parse(currentView?.Data));
        displayPreload(false);
      });
    });
  };

  returnViews = () => {
    return this.state.views;
  };

  onSetDefaultView = (e, type) => {
    const { chkSetUserDefaultView, chkSetSiteDefaultView } =
      this.state.selectors;

    this.setState({
      selectors: {
        ...this.state.selectors,
        chkSetSiteDefaultView:
          type === "Site" ? e.value : chkSetSiteDefaultView,
        chkSetUserDefaultView:
          type === "User" ? e.value : chkSetUserDefaultView,
      },
    });
  };

  onChkValueChanged = (e) => {
    this.setState({ selectors: { ...this.state.selectors, [e.tag]: e.value } });
  };

  onCancelCustomView = () => {
    let elem = document.getElementById("viewDescription");
    elem.removeAttribute("UPId");
    elem.value = "";

    this.setState({ ...initialState, customViews: this.state.customViews });
  };

  onSaveCustomView = () => {
    let elem = document.getElementById("viewDescription");
    let viewName = elem.value;
    let elemUPId = elem.getAttribute("UPId") !== null ? elem.getAttribute("UPId") : 0;

    const { t } = this.props;


    if (viewName !== "") {
      if (this.state.views?.filter((view) => view.ViewDescription.toLowerCase() === viewName.toLowerCase() && view.UPId !== elemUPId).length === 0) { //Check that the name doesn't already exist
        let data = "";
        if (!isTablet())
          if (this.state.event === "copy") data = this.state.viewCopy;
          else data = JSON.stringify(this.props.refGrid.current.instance.state());
        else {
          let cols = [];
          let selectedTailsFields = this.props.selectedTailsFields();
          selectedTailsFields.forEach((field, i) => {
            cols.push({
              dataField: field,
              name: field,
              visible: true,
              visibleIndex: i,
              width: "50px",
            });
          });
          let obj = {
            allowedPageSizes: [],
            columns: cols,
            filterPanel: { filterEnabled: true },
            filterValue: null,
            pageIndex: 0,
            pageSize: 20,
            searchText: "",
          };
          data = JSON.stringify(obj);
        }

        let viewClass = {
          UPId: elemUPId,
          ViewType: 99,
          UserId: getUserId(),
          ViewDescription: elem.value,
          Data: data,
          ScreenDescription: this.props.viewName,
          ScreenId: 1,
          DefaultViewId: 22,
          IsPublic: this.state.selectors.chkPublicView,
          IsDefault: 0,
          IsUserDefault: this.state.selectors.chkUserDefaultView,
          IsSiteDefault: false,
          MenuItemIndex: 0,
          IsWrapEnable: false,
        };

        saveCustomView(viewClass).then(() => {
          elem.value = "";
          elem.removeAttribute("UPId");

          this.setState(
            {
              ...initialState,
              customViews: this.state.customViews,
            },
            () => {
              this.getViews();
            }
          );
        });
      } else {
        error(t(`This view description already exists`));
      }
    } else {
      warning(t(`You must enter a description.`));
    }
  };

  onCopyCustomView = (view) => {
    this.setState({
      openFormView: true,
      event: "copy",
      viewCopy: view.data,
    });
  };

  onRemoveCustomView = (view) => {
    this.setState({ openFormView: true, event: "delete", viewCopy: "" }, () => {
      let elem = document.getElementById("viewDescription");
      elem.value = view.ViewDescription;
      elem.disabled = true;
      elem.setAttribute("UPId", view.UPId);
    });
  };

  onAceptRemoveCustomView = () => {
    let elem = document.getElementById("viewDescription");
    let view = Object.assign({}, this.state.currentView);

    if (view.UPId === parseInt(elem.getAttribute("UPId"))) view.UPId = null;

    deleteCustomView(parseInt(elem.getAttribute("UPId"))).then(() => {
      this.setState(
        { openFormView: false, event: "", currentView: view },
        () => {
          elem.removeAttribute("UPId");
          elem.disabled = false;
          elem.value = "";
          this.getViews();
        }
      );
    });
  };

  onNewView = () => {
    this.setState(
      {
        event: "new",
        openFormView: true,
        viewCopy: "",
        selectors: {
          ...this.state.selectors,
          chkPublicView: false,
          chkUserDefaultView: false,
          chkSetSiteDefaultView: false,
          chkSetUserDefaultView: false,
        },
      },
      () => {
        let elem = document.getElementById("viewDescription");
        elem.value = "";
        elem.disabled = false;
        elem.removeAttribute("UPId");
      }
    );
  };

  onSelectView = (view) => {
    const { chkSetSiteDefaultView, chkSetUserDefaultView } =
      this.state.selectors;

    if (chkSetUserDefaultView) {
      setUserDefaultView(view.UPId)
        .then(() => {
          this.setState({
            selectors: {
              ...this.state.selectors,
              chkSetUserDefaultView: false,
            },
          });
          this.getViews();
        })
        .catch((ex) => {
          this.setState({
            selectors: {
              ...this.state.selectors,
              chkSetUserDefaultView: false,
            },
          });
          error(ex);
        });
    } else if (chkSetSiteDefaultView) {
      setSiteDefaultView(view.UPId)
        .then(() => {
          this.setState({
            selectors: {
              ...this.state.selectors,
              chkSetSiteDefaultView: false,
            },
          });
          this.getViews();
        })
        .catch((ex) => {
          this.setState({
            selectors: {
              ...this.state.selectors,
              chkSetSiteDefaultView: false,
            },
          });
          error(ex);
        });
    } else {
      this.setState(
        {
          event: "",
          viewCopy: "",
          currentView: view,
          openFormView: false,
        },
        () => {
          let data = JSON.parse(view.Data);
          if (!isTablet()) this.props.refGrid.current.instance.state(data);
          else this.props.applyCustomView(data);
        }
      );
    }
  };

  collapseUnassignedTSGroup = () => {
    displayPreload(true);
    setTimeout(() => {
      this.props.refGrid.current.instance.collapseRow(["Unassigned"]);
      displayPreload(false);
    }, 250);
  };

  onClearUserDefaultView = () => {
    let view = this.state.views.find((view) => view.IsUserDefault);

    if (view) {
      view.IsUserDefault = false;
      view.UserId = getUserId();
      saveCustomView(view).then(() => this.getViews());
    }
  };

  onEditCurrentView = () => {
    let view = this.state.currentView;

    this.setState(
      {
        openFormView: true,
        event: "update",
        selectors: {
          ...this.state.selectors,
          chkPublicView: view.IsPublic,
          chkUserDefaultView: view.IsUserDefault,
        },
        inputLength: view.ViewDescription.length
      },
      () => {
        let elem = document.getElementById("viewDescription");
        elem.value = view.ViewDescription;
        if (view.UPId !== null) elem.setAttribute("UPId", view.UPId);
      }
    );
  };

  render() {
    const { views, currentView, event, openFormView, selectors } = this.state;
    const { t } = this.props;

    return (
      <div className={styles.container}>
        {(selectors.chkSetSiteDefaultView ||
          selectors.chkSetUserDefaultView) && (
          <div className={styles.setViewInfo}>
            {/* <img alt="" src={icons.info} /> */}
            <Icon name="circle-info" />
            <label>
              {t(
                `Click on the view you want to set as ${
                  selectors.chkSetSiteDefaultView ? "Site" : "User"
                } Default.`
              )}
            </label>
          </div>
        )}
        <label className={styles.currentView}>
          {t("Current View")}:&nbsp;<b>{currentView.ViewDescription}</b>
        </label>

        <div
          className={[
            styles.newCustomView,
            !openFormView ? styles.newCustomView_hide : "",
          ].join(" ")}
        >
          <Input
            id="viewDescription"
            type="text"
            label={t("View Description")}
            border
            onChange={(e) => this.setState({inputLength: e.target.value.length})}
            maxLength={40}
          />
          <div id="viewDescCharRemaining">{40 - this.state.inputLength} {t("Characters Remaining")}</div>
          <div className={styles.flexRow}>
            <CheckBox
              id="chkPublicView"
              tag="chkPublicView"
              text={t("Public View (Will be seen by all users)")}
              disabled={event === "delete"}
              value={selectors.chkPublicView}
              onValueChanged={(e) => this.onChkValueChanged(e)}
            />
            <CheckBox
              id="chkUserDefaultView"
              tag="chkUserDefaultView"
              text={t("Set User Default View")}
              disabled={event === "delete"}
              value={selectors.chkUserDefaultView}
              onValueChanged={(e) => this.onChkValueChanged(e)}
            />
          </div>
          <div className={[styles.flexRow, styles.flexEnd].join(" ")}>
            <Button
              id="btnCancelCustomView"
              text={t("Cancel")}
              icon="ban"
              onClick={this.onCancelCustomView}
            />
            <Button
              id="btnSaveCustomView"
              text={t("Save View")}
              icon="save"
              visible={event !== "delete"}
              onClick={this.onSaveCustomView}
            />
            <Button
              id="btnDeleteCustomView"
              text={t("Delete View")}
              icon="save"
              visible={event === "delete"}
              onClick={this.onAceptRemoveCustomView}
            />
          </div>
        </div>

        <div className={styles.viewSetting}>
          <div className={styles.buttonsGroup}>
            <Button
              id="btnNewCustomView"
              text={t("New Custom View")}
              disabled={false}
              onClick={this.onNewView}
            />
            <Button
              id="btnClearUserDefaultView"
              text={t("Clear User Default View")}
              disabled={openFormView}
              onClick={this.onClearUserDefaultView}
            />
            <Button
              id="btnEditCurrentView"
              text={t("Edit Current View")}
              disabled={
                systemsViews.indexOf(currentView.ViewDescription) > 0 ||
                currentView === "" ||
                currentView.UserId !== getUserId()
              }
              onClick={this.onEditCurrentView}
            />
          </div>
          <div>
            <CheckBox
              id="chkSetUserDefaultView"
              text={t("Set User Default View")}
              value={selectors.chkSetUserDefaultView}
              disabled={openFormView}
              onValueChanged={(e) => this.onSetDefaultView(e, "User")}
            />
            {![1, 2].includes(getUserRole()) && (
              <CheckBox
                id="chkSetSiteDefaultView"
                text={t("Set Site Default View")}
                value={selectors.chkSetSiteDefaultView}
                disabled={openFormView}
                onValueChanged={(e) => this.onSetDefaultView(e, "Site")}
              />
            )}
          </div>
        </div>

        <div className={styles.viewSelector}>
          <ViewBox
            t={t}
            views={[
              {
                id: "vitSystemViews",
                title: "System Views",
                visible: true,
                list: views?.filter(
                  (view) => systemsViews.indexOf(view.ViewDescription) !== -1
                ),
              },
              {
                id: "vitPublicViews",
                title: "Public Views",
                visible: true,
                list: views?.filter(
                  (view) =>
                    view.IsPublic &&
                    systemsViews.indexOf(view.ViewDescription) === -1
                ),
              },
              {
                id: "vitPrivateViews",
                title: "Private Views",
                visible: !selectors.chkSetSiteDefaultView,
                list: views?.filter((view) => !view.IsPublic),
              },
            ]}
            onSelectView={this.onSelectView}
            onCopyCustomView={this.onCopyCustomView}
            onRemoveCustomView={this.onRemoveCustomView}
            hidePrivateViews={selectors.chkSetSiteDefaultView}
          />
        </div>
      </div>
    );
  }
}

export default CustomViewDialog;

export function getDefaultViews() {
  let views = customViewDialog.state.views;

  return (
    views?.find((view) => view.IsUserDefault) ??
    views?.find((view) => view.IsSiteDefault) ??
    null
  );
}
