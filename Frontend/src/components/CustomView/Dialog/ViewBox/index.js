import React, { PureComponent } from "react";
import { getUserId } from "../../../../services/auth";
import { Icon } from "react-fa";
import styles from "../styles.module.scss";

const ViewItem = (props) => {
  const {
    name,
    view,
    remove,
    onSelectView,
    onCopyCustomView,
    onRemoveCustomView,
  } = props;

  return (
    <div className={styles.viewItem}>
      {remove && (
        <div className={styles.viewItem_remove}>
          <Icon name="trash" onClick={() => onRemoveCustomView(view)} />
        </div>
      )}

      {!remove && (
        <div className={styles.viewItem_lock}>
          <Icon name="lock" />
        </div>
      )}

      <div className={styles.viewItem_copy}>
        <Icon name="copy" onClick={() => onCopyCustomView(view)} />
      </div>

      <span
        className={styles.viewItem_title}
        onClick={() => onSelectView(view)}
      >
        {name}
      </span>

      {view.IsSiteDefault && (
        <div className={styles.viewItem_globe}>
          <Icon name="globe" />
        </div>
      )}

      {view.IsUserDefault && (
        <div className={styles.viewItem_user}>
          <Icon name="user" />
        </div>
      )}
      <br />
    </div>
  );
};

class ViewBox extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {};
  }

  render() {
    const {
      t,
      views,
      onSelectView,
      onCopyCustomView,
      onRemoveCustomView,
    } = this.props;

    return (
      <React.Fragment>
        {views.map(
          (view) =>
            view.visible && (
              <div
                id={view.id || undefined}
                key={view.title}
                className={styles.viewBox}
              >
                <label>{t(view.title)}</label>
                {view.list?.map((v, i) => (
                  <ViewItem
                    key={i}
                    view={v}
                    name={v.ViewDescription}
                    remove={v.UserId === getUserId()}
                    onSelectView={(e) => onSelectView(v)}
                    onCopyCustomView={(e) => onCopyCustomView(v)}
                    onRemoveCustomView={(e) =>
                      v.title !== "System Views"
                        ? onRemoveCustomView(v)
                        : undefined
                    }
                  />
                ))}
              </div>
            )
        )}
      </React.Fragment>
    );
  }
}

export default ViewBox;
