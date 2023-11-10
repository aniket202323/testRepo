import React, { Component } from "react";
import Button from "../../../../../components/Button";
import { infoDTDetails } from "../options";
import styles from "../styles.module.scss";

export default class DowntimeDetails extends Component {
  constructor(props) {
    super(props);

    this.state = {
      index: 0,
    };
  }

  shouldComponentUpdate = (nextProps, nextState) => {
    if (nextProps.visible !== this.props.visible) {
      this.setState({ index: 0 });
      return true;
    }
    if (
      nextProps.visible !== this.props.visible ||
      nextState.index !== this.state.index
    ) {
      return true;
    } else return false;
  };

  previous = () => {
    const index = this.state.index;
    if (index !== 0) {
      this.setState({
        index: index - 1,
      });
    }
  };

  next = () => {
    const index = this.state.index;
    if (index !== this.props.data.length) {
      this.setState({
        index: index + 1,
      });
    }
  };

  previousAll = () => {
    this.setState({ index: 0 });
  };

  nextAll = () => {
    this.setState({ index: this.props.data.length - 1 });
  };

  render() {
    const { t, data = [] } = this.props;
    const { index } = this.state;

    return (
      <React.Fragment>
        <div className={styles.dataGridContainer}>
          <div>
            {infoDTDetails.map((j, i) => (
              <div key={i}>
                {j.type !== "LineSeparator" ? (
                  <>
                    <label className={styles.title}>{t(j.title)}:</label>
                    {data.length > 0 ? data[index][j.field] : ""} <br />
                  </>
                ) : (
                  <hr />
                )}
              </div>
            ))}
            <br />
          </div>

          <div className={styles.btnsNavegation}>
            <Button
              id="btnDoublePrevious"
              icon="angle-double-left"
              disabled={index === 0}
              onClick={this.previousAll}
            />
            <Button
              id="btnPrevious"
              icon="angle-left"
              disabled={index === 0}
              onClick={this.previous}
            />
            <label>
              {t("Page")} {index + 1} {t("of")} {data.length}
            </label>
            <Button
              id="btnNext"
              icon="angle-right"
              disabled={index === data.length - 1}
              onClick={this.next}
            />
            <Button
              id="btnDoubleNext"
              icon="angle-double-right"
              disabled={index === data.length - 1}
              onClick={this.nextAll}
            />
          </div>
        </div>
      </React.Fragment>
    );
  }
}
