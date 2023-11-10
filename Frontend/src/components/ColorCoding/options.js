export const getColorCoding = (report) => {
  if (report === "eMag") return eMagColorCoding;
  else return complianceColorCoding;
};

//#region color coding for report

const eMagColorCoding = [
  {
    name: "Ok",
    bgColor: "#00b055",
    labelColor: "#00000",
  },
  {
    name: "Done Late",
    bgColor: "#ff7000",
    labelColor: "#00000",
  },
  {
    name: "Pending",
    bgColor: "#003daf",
    labelColor: "#ffffff",
  },
  {
    name: "Late",
    bgColor: "#ffb80f",
    labelColor: "#00000",
  },
  {
    name: "Missed",
    bgColor: "#101010",
    labelColor: "#ffffff",
  },
  {
    name: "Defect",
    bgColor: "#fe1a0e",
    labelColor: "#ffffff",
  },
];

const complianceColorCoding = [
  {
    name: "Lower Reject",
    bgColor: "#DC143C",
    labelColor: "#ffffff",
  },
  {
    name: "Lower Warning",
    bgColor: "#FFA500",
    labelColor: "#00000",
  },
  {
    name: "Lower User",
    bgColor: "#FFFF00",
    labelColor: "#00000",
  },
  {
    name: "Upper User",
    bgColor: "#FFFF00",
    labelColor: "#00000",
  },
  {
    name: "Upper Warning",
    bgColor: "#FFA500",
    labelColor: "#00000",
  },
  {
    name: "Upper Reject",
    bgColor: "#DC143C",
    labelColor: "#ffffff",
  },
];

//#endregion
