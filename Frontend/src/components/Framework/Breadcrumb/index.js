import React, { PureComponent } from "react";
import { Icon } from "react-fa";
import { isTablet } from "../../../utils";
import { subscribeBreadcrumbEvents } from "./events";
import styles from "./styles.module.scss";

class Breadcrumb extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      breadcrumbChild: null,
    };
  }

  componentDidMount = () => {
    subscribeBreadcrumbEvents().subscribe((breadcrumbChild) =>
      this.setState({ breadcrumbChild })
    );
  };

  render() {
    const { route } = this.props;

    if (route === undefined) return null;

    let child = React.Children.map(this.props.children, (child, index) => {
      if (child) {
        return React.cloneElement(child, {
          state: "main",
        });
      }
    });

    return (
      <React.Fragment>
        <div
          className={[styles.container, "breadcrumb"].join(" ")}
          style={{
            display:
              sessionStorage.getItem("OpsHubPage") === "MyRoutes" || isTablet()
                ? "none"
                : "inline-flex",
          }}
        >
          <div>
            {route.split("|").map((r, index) => (
              <span key={index}>
                {r}&nbsp;
                {route.split("|").length - 1 !== index ? (
                  <Icon className={styles.angleRight} name="angle-right" />
                ) : (
                  ""
                )}
              </span>
            ))}
          </div>
          <div>{child}</div>
          <div>{this.state.breadcrumbChild}</div>
        </div>
      </React.Fragment>
    );
  }
}

export default Breadcrumb;
