import React, { PureComponent, Fragment, memo } from "react";
import { translate } from "react-i18next";
import styles from "./styles.module.scss";
import { Icon } from "react-fa";
import memoize from "memoize-one";
import Button from "../Button";

class SelectBox extends PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      storeFilter: [],
      searchValue: "",
    };
  }

  static defaultProps = {
    value: [],
    store: [],
    isMultiple: true,
    labelKey: "text",
    valueKey: "value",
    flagKey: "flag",
    disableItems: [],
    lastSelected: "",
  };

  componentDidMount = () => {
    let tag = "[data-tag='set-scroll']";
    let elements = document.querySelectorAll(tag);
    elements.forEach((elem) => {
      elem.removeEventListener("mousewheel", this.mousewheelEvent, false);
      elem.addEventListener("mousewheel", this.mousewheelEvent, false);
    });
  };

  mousewheelEvent = (e) => {
    e.preventDefault();
    //if: up
    //else: down
    if (e.wheelDelta >= 0) {
      let parent = e.target.parentElement;
      parent.scrollTo(0, parent.scrollTop - e.target.offsetHeight);
    } else {
      let parent = e.target.parentElement;
      parent.scrollTo(0, parent.scrollTop + e.target.offsetHeight);
      // e.target.offsetHeight;
      // e.target.parentElement.offsetHeight;
    }
  };

  onClick = (e, selectedValue) => {
    e.preventDefault();
    this.setState({ lastSelected: selectedValue });
    if (e.shiftKey) {
      if (!this.props.isMultiple) {
        e.preventDefault();
        return;
      }
      const { store, onChange, value, valueKey } = this.props;

      const { searchValue, storeFilter, lastSelected } = this.state;
      let startPos = store.map((v) => v[valueKey]).indexOf(lastSelected);
      let endPos = store.map((v) => v[valueKey]).indexOf(selectedValue);
      let currentValue = value || [];
      let start = false;
      let range = [];
      let ds;
      if (searchValue !== "") {
        ds = storeFilter;
      } else {
        ds = store;
      }
      ds.forEach((v) => {
        if (
          v[valueKey] === (startPos > endPos ? selectedValue : lastSelected)
        ) {
          start = true;
        }
        if (start) {
          range.push(v[valueKey]);
          if (
            v[valueKey] === (startPos > endPos ? lastSelected : selectedValue)
          )
            start = false;
        }
      });
      onChange(Array.from(new Set([...currentValue, ...range])));
    } else {
      const { onChange, value, isMultiple } = this.props;
      let currentValue = value || [];
      if (onChange) {
        if (!isMultiple) onChange([selectedValue]);
        else {
          const index = currentValue.findIndex((v) => v === selectedValue);
          if (index < 0) onChange([...currentValue, selectedValue]);
          else {
            let current = currentValue.slice();
            current.splice(index, 1);
            onChange(current);
          }
        }
      }
    }
  };

  createStyles = () => {
    let names = [styles.container];
    if (this.props.className) names.push(this.props.className);
    if (this.props.isDisable) names.push(styles.isDisable);
    return names.join(" ");
  };

  searching = (e) => {
    let filterContent = this.props.store.filter((v) => {
      if (
        v[this.props.labelKey]
          .toUpperCase()
          .indexOf(e.target.value.toUpperCase()) !== -1
      )
        return v;
      return null;
    });
    this.setState({ storeFilter: filterContent, searchValue: e.target.value });
  };

  selectAll = () => {
    const { store, valueKey, value, isDisable, disableItems } = this.props;
    const { storeFilter, searchValue } = this.state;

    if (!isDisable)
      if (searchValue !== "") {
        if (storeFilter.length > 0)
          if (value === null) {
            this.props.onChange([
              ...storeFilter
                .map((v) => v[valueKey])
                .filter((x) => !disableItems.includes(x)),
            ]);
          } else {
            if (this.diference(storeFilter, value, valueKey, disableItems)) {
              //select all search

              this.props.onChange([
                ...new Set([
                  ...value,
                  ...value
                    .filter((x) =>
                      storeFilter.map((y) => y[valueKey]).includes(x)
                    )
                    .concat(
                      storeFilter
                        .map((v) => v[valueKey])
                        .filter((x) => !value.includes(x))
                    )
                    .filter((x) => !disableItems.includes(x)),
                ]),
              ]);
            } else {
              //deselect all search
              this.props.onChange([
                ...value
                  .filter(
                    (x) => !storeFilter.map((y) => y[valueKey]).includes(x)
                  )
                  .filter((x) => !disableItems.includes(x)),
              ]);
            }
          }
      } else {
        if (store.length > 0)
          if (value === null) {
            this.props.onChange([
              ...store
                .map((v) => v[valueKey])
                .filter((x) => !disableItems.includes(x)),
            ]);
          } else {
            if (this.diference(store, value, valueKey, disableItems)) {
              //select all
              this.props.onChange([
                ...store
                  .map((v) => v[valueKey])
                  .filter((x) => !disableItems.includes(x)),
              ]);
            } else {
              //deselect all
              this.props.onChange([]);
            }
          }
      }
  };

  diference = memoize(
    (storeFilter, value, valueKey, disableItems) =>
      storeFilter.length !==
      storeFilter.filter((v) => {
        return value.indexOf(v[valueKey]) !== -1;
      }).length +
        (disableItems !== undefined
          ? storeFilter.filter((v) => {
              return disableItems.indexOf(v[valueKey]) !== -1;
            }).length
          : 0)
  );

  componentDidUpdate = (prevProps, prevState) => {
    if (prevProps.id !== this.props.id) {
      this.setState({ searchValue: "" });
    }
  };

  render() {
    const {
      t,
      id,
      labelKey,
      valueKey,
      store,
      text,
      isLoading,
      isDisable,
      disabledMessage,
      disableItems,
      enableSelectAll,
      enableClear,
      flagKey,
      visible = true,
    } = this.props;
    const { storeFilter, searchValue } = this.state;
    const value = this.props.value || SelectBox.defaultProps.value;

    return (
      visible && (
        <div id={id || undefined} className={this.createStyles()}>
          {text ? (
            <div className={styles.text}>
              {t(text)}
              <br />
              {value.length > 0 ? (
                enableClear ? (
                  <div>
                    <span className={styles.countSelected}>
                      {value.length + " " + t("selected")}
                    </span>
                    <Button
                      text={t("clear")}
                      classes={styles.mini}
                      onClick={() =>
                        this.props.onClear
                          ? this.props.onClear()
                          : this.props.onChange([])
                      }
                    />
                  </div>
                ) : (
                  ""
                )
              ) : (
                isDisable && (
                  <span className={styles.countSelected}>{t("Disabled")}</span>
                )
              )}
            </div>
          ) : null}

          <div className={styles.searchContainer}>
            <input
              className={styles.search}
              type={"text"}
              placeholder={t("Search") + "..."}
              onChange={this.searching}
              value={searchValue}
            />
            {enableSelectAll && (
              <Fragment>
                <button
                  className={styles.selectAllBtn}
                  onClick={this.selectAll}
                >
                  {searchValue !== ""
                    ? this.diference(
                        storeFilter,
                        value,
                        valueKey,
                        disableItems,
                        store
                      ) || storeFilter.length === 0
                      ? t("Select All")
                      : t("Deselect All")
                    : this.diference(store, value, valueKey, disableItems) ||
                      store.length === 0
                    ? t("Select All")
                    : t("Deselect All")}
                </button>
              </Fragment>
            )}
          </div>

          <ul data-tag="set-scroll" className={styles.select}>
            {isLoading ? (
              <div className={styles.refreshContainer}>
                <Icon name="refresh" spin className={styles.refresh} />
              </div>
            ) : searchValue === "" ? (
              store.length > 0 ? (
                store.map((v) => (
                  <li
                    key={Math.random().toString(36).slice(2).substring(0, 8)}
                    onClick={(e) => this.onClick(e, v[valueKey])}
                    className={
                      disableItems.includes(v[valueKey])
                        ? styles.isDisable
                        : value.includes(v[valueKey])
                        ? styles.selected
                        : ""
                    }
                    title={
                      disableItems.includes(v[valueKey])
                        ? disabledMessage || ""
                        : ""
                    }
                  >
                    {v[labelKey]}
                    {v[flagKey] && (
                      <span className={styles.flag}>{v[flagKey]}</span>
                    )}
                  </li>
                ))
              ) : (
                ""
              )
            ) : (
              storeFilter.map((v) => (
                <li
                  // key={v[valueKey]}
                  key={Math.random().toString(36).slice(2).substring(0, 8)}
                  onClick={(e) => this.onClick(e, v[valueKey])}
                  className={
                    disableItems.includes(v[valueKey])
                      ? styles.isDisable
                      : value.includes(v[valueKey])
                      ? styles.selected
                      : ""
                  }
                >
                  {v[labelKey]}
                  {v[flagKey] && (
                    <span className={styles.flag}>{v[flagKey]}</span>
                  )}
                </li>
              ))
            )}
          </ul>
        </div>
      )
    );
  }
}

export default translate()(memo(SelectBox));
