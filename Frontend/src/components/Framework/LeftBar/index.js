import React, { PureComponent } from "react";
import Item from "./Item";
import styles from "./styles.module.scss";
import { getUserRole } from "../../../services/auth";

function GroupItems(props) {
  let content = React.Children.map(props.children, (child) => {
    if (child) {
      return React.cloneElement(child);
    }
  });

  return (
    <div>
      <h6 className={styles.itemGroup}>{props.title}</h6>
      {content}
    </div>
  );
}

class LeftBar extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      globalAccessLevel: 0,
    };
  }

  componentDidMount = () => {
    let globalAccessLevel = getUserRole();
    this.setState({
      globalAccessLevel,
    });
  };

  render() {
    const { t, open, items } = this.props;
    const { globalAccessLevel } = this.state;

    return (
      <div
        style={{
          display:
            sessionStorage.getItem("OpsHubPage") === "MyRoutes"
              ? "none"
              : "flex",
        }}
        className={
          !open
            ? [styles.root, styles.left_hide, styles.left].join(" ")
            : [styles.root, styles.left].join(" ")
        }
      >
        <div className={styles.container}>
          {items.length > 0 &&
            items.map(
              (key) =>
                key.accesLevel.includes(globalAccessLevel) && (
                  <GroupItems key={key.text} title={t(key.text)}>
                    {key.items.map(
                      (subitem) =>
                        subitem.accesLevel?.includes(globalAccessLevel) && (
                          <Item
                            key={subitem.text}
                            text={t(subitem.text)}
                            name={subitem.text}
                            imgIcon={subitem.imgIcon}
                            selected={this.props.selectedItem === subitem.text}
                            onClick={(name) => this.props.onClick(name)}
                          />
                        )
                    )}
                  </GroupItems>
                )
            )}
        </div>
      </div>
    );
  }
}

export default LeftBar;
