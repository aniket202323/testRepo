

CREATE PROCEDURE dbo.spMES_GetProcessOrdersOnUnits
    @LineId         INT,         -- Line of units to return PO details for.
    @UnitId         INT,         -- Unit to return PO details for
    @StatusSet      NVARCHAR(30) -- Set of status ID as a string
AS

  /* Temp table to hold the StatusSet values after parsing */
  DECLARE @StatusValues Table (
    StatusValue Int)

  /* Parse the status set by into a temp table for later selection */
  IF @StatusSet IS NOT NULL
    BEGIN
      INSERT INTO @StatusValues(StatusValue)
        SELECT Id
        FROM dbo.fnCMN_IdListToTable('Production_Plan_Statuses ',@StatusSet,',')
    END

  /* Split the query into 2 steps to reduce the complexity and execution time
     First step is get the POs and Path Units filtered by status*/
  DECLARE @POs Table (PP_Id int, Path_Id int, Prod_Id int, PU_Id int,
    Process_Order nvarchar(50), Forecast_Quantity float, Actual_Start_Time datetime, PP_Status_Id int,
    Forecast_Start_Date datetime,Forecast_End_Date datetime)
  INSERT INTO @POs(PP_Id, Path_Id, Prod_Id, PU_Id,
                   Process_Order, Forecast_Quantity, Actual_Start_Time, PP_Status_Id,
                   Forecast_Start_Date, Forecast_End_Date)
    SELECT po.PP_Id, po.Path_Id, po.Prod_Id, pathUnits.PU_Id,
      po.Process_Order, po.Forecast_Quantity, po.Actual_Start_Time, po.PP_Status_Id,
      po.Forecast_Start_Date, po.Forecast_End_Date
    FROM [dbo].Production_Plan po
      JOIN [dbo].PrdExec_Path_Units pathUnits
        ON pathUnits.Path_Id = po.Path_Id
    WHERE po.PP_Status_Id in (SELECT StatusValue FROM @StatusValues) AND
          (@UnitId is null or @UnitId = pathUnits.PU_Id)

  /* Add in the unit and product info */
  SELECT unit.PL_Id as LineId,
         po.PU_Id as UnitId,
         po.PP_Id as ProcessOrderId,
         po.Process_Order as ProcessOrderName,
         product.Prod_Id as ProductId,
         product.Prod_Desc as ProductName,
         po.Forecast_Quantity as ProductQuantity,
         dbo.fnServer_CmnConvertFromDBTime(po.Actual_Start_Time,'UTC') as StartTime,
         po.PP_Status_Id as status,
         CASE WHEN po_unit.Start_Time is null
           THEN 0
         ELSE 1
         END as IsActiveOnUnit,
         (SELECT innerPathUnits.PU_ID as ProductionPointUnitId
          FROM [dbo].PrdExec_Path_Units innerPathUnits
          WHERE innerPathUnits.Path_Id = po.Path_Id AND
                innerPathUnits.Is_Production_Point = 1) as ProductionPointUnitId,
         dbo.fnServer_CmnConvertFromDBTime(po.Forecast_Start_Date,'UTC') as PlannedStartDate,
         dbo.fnServer_CmnConvertFromDBTime(po.Forecast_End_Date,'UTC') as PlannedEndDate,
         dbo.fnServer_CmnConvertFromDBTime(po_unit.Start_Time,'UTC') as UnitStartTime
  FROM @POs po
    JOIN [dbo].Prod_Units_Base unit
      ON unit.PU_Id = po.PU_Id
    JOIN [dbo].Products_Base product
      ON product.Prod_Id = po.Prod_Id
    /* A PO that is active can not be null so include the active PO info */
    LEFT JOIN [dbo].[Production_Plan_Starts] po_unit
      ON po_unit.PU_Id = po.PU_Id and po_unit.PP_Id = po.PP_Id
  WHERE (@LineId is null or @LineId = unit.PL_Id)
        /* Weed out the completed (on this unit) process orders */
        AND (po_unit.End_Time is null)
  ORDER BY LineId,
    /* In order that the unit appears on the line (not path). Sorting by path order was resulting in incorrect ordering
       when POs had differing path lengths. */
    unit.PU_Order,
    /* Current PO should be on top */
    CASE WHEN po_unit.Start_Time is null THEN 1 ELSE 0 END,
    /* For active POs, earliest time is longest running. Put nulls at the end */
    CASE WHEN po.Actual_Start_Time is null THEN 1 ELSE 0 END, po.Actual_Start_Time,
    /* For not active POs, earliest time could be the next candidate. */
    po.Forecast_Start_Date
