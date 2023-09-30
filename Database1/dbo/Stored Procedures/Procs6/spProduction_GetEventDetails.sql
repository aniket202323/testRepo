
CREATE PROCEDURE dbo.spProduction_GetEventDetails @EventId INT

 AS
BEGIN

    SELECT Top 1 
    	   E.Event_Id AS                                             EventId,
           E.Event_Num AS                                            EventNumber,
           E.PU_Id AS                                                UnitId,
           PU.PU_Desc AS                                             UnitDesc,
           dbo.fnserver_CmnConvertFromDbTime(E.Start_Time, 'UTC') AS StartTime,
           dbo.fnserver_CmnConvertFromDbTime(E.TimeStamp, 'UTC') AS  EndTime,
           dbo.fnserver_CmnConvertFromDbTime(e.Entry_On, 'UTC') AS   EntryOn,
           PS2.Prod_Id AS                                            ProductId,
           PB2.Prod_Code AS                                          ProductCode,
           PB2.Prod_Desc AS                                          ProductDescription,
           E.Applied_Product AS                                      AppliedProductId,
           PB.Prod_Code AS                                           AppliedProductCode,
           PB.Prod_Desc AS                                           AppliedProductDescription,
           E.Event_Status AS                                         EventStatus,
           PS.ProdStatus_Desc AS                                     EventStatusDesc,
           ISNULL(PS.LockData, 0) AS                                 IsLockEventData,
           ES.Dimension_X_Name AS                                    DimensionXName,
           ES.Dimension_X_Eng_Units AS                               DimensionXUnit,
           CASE WHEN ES.Dimension_Y_Enabled = 1 THEN ES.Dimension_Y_Name ELSE NULL END  AS                                    DimensionYName,
           CASE WHEN ES.Dimension_Y_Enabled = 1 THEN ES.Dimension_Y_Eng_Units ELSE NULL END  AS                               DimensionYUnit,
           CASE WHEN ES.Dimension_Z_Enabled = 1 THEN ES.Dimension_Z_Name ELSE NULL END  AS                                    DimensionZName,
           CASE WHEN ES.Dimension_Z_Enabled = 1 THEN ES.Dimension_Z_Eng_Units ELSE NULL END  AS                               DimensionZUnit,
           CASE WHEN ES.Dimension_A_Enabled = 1 THEN ES.Dimension_A_Name ELSE NULL END  AS                                    DimensionAName,
           CASE WHEN ES.Dimension_A_Enabled = 1 THEN ES.Dimension_A_Eng_Units ELSE NULL END  AS                               DimensionAUnit,
           ED.Initial_Dimension_X AS                                 InitialDimensionX,
           ED.Final_Dimension_X AS                                   FinalDimensionX,
           ED.Initial_Dimension_Y AS                                 InitialDimensionY,
           ED.Final_Dimension_Y AS                                   FinalDimensionY,
           ED.Initial_Dimension_Z AS                                 InitialDimensionZ,
           ED.Final_Dimension_Z AS                                   FinalDimensionZ,
           ED.Initial_Dimension_A AS                                 InitialDimensionA,
           ED.Final_Dimension_A AS                                   FinalDimensionA,
           E.Comment_Id AS                                           CommentId,
           C.Comment_Text AS                                         Comment
           FROM Events AS e
                JOIN Prod_Units_Base AS PU ON PU.PU_Id = E.PU_Id
                JOIN Production_Status AS PS ON PS.ProdStatus_Id = E.Event_Status
                LEFT JOIN Event_Details AS ED ON ED.Event_Id = E.Event_Id
                LEFT JOIN Comments AS C ON C.Comment_Id = E.Comment_Id
                LEFT JOIN Event_Configuration AS EC ON EC.ET_Id = 1
                                                       AND EC.PU_Id = E.PU_Id
                LEFT JOIN Event_Subtypes AS ES ON ES.Event_Subtype_Id = EC.Event_Subtype_Id
                LEFT JOIN Products_Base AS PB ON PB.prod_Id = E.Applied_Product
                LEFT JOIN dbo.Production_Starts AS PS2 ON PU.PU_Id = PS2.PU_Id
                                                      AND E.TimeStamp >= PS2.Start_Time
                                                      AND (E.TimeStamp < PS2.End_Time
                                                               OR PS2.End_Time IS NULL)
															  
                LEFT JOIN dbo.Products_Base AS PB2 ON PS2.Prod_Id = PB2.Prod_Id
           WHERE E.Event_Id = @EventId
           ORDER BY ISNULL(PS2.Start_Id,E.Event_Id) DESC
END
