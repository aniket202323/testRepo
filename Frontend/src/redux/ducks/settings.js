const UPDATE_SETTINGS = "UPDATE_SETTINGS";

const initialState = {
  navbar: {
    opened: window.innerWidth >= 992,
    group: "Tasks Selection",
    itemSelected: "Plant Model",
  },
};

const fn = (state = initialState, action) => {
  switch (action.type) {
    case UPDATE_SETTINGS:
      return Object.assign({}, state, action.elements, {
        navbar: Object.assign({}, state.navbar, action.elements.navbar),
      });
    default:
      return state;
  }
};

export const updateSettings = (elements) => ({
  type: UPDATE_SETTINGS,
  elements,
});

export default fn;
