
CREATE PROCEDURE dbo.spProductChange_GetMachines @UnitIds NVARCHAR(max)

 AS
BEGIN

    DECLARE @AllUnits TABLE(Pu_Id   INT,
                            Pu_Desc NVARCHAR(100))
    DECLARE @Xml XML
    SET @Xml = CAST('<X>'+replace(@UnitIds, ',', '</X><X>')+'</X>' AS XML)
    INSERT INTO @AllUnits( Pu_Id,
                           Pu_Desc )
    SELECT Pu.Pu_Id,
           Pu.PU_Desc FROM(SELECT N.value('.', 'int') AS Pu_Id FROM @Xml.nodes('X') AS T(N)) AS T
                          JOIN Prod_Units_base AS Pu ON Pu.PU_Id = T.Pu_Id;

    SELECT PU_Id,
           PU_Desc
           FROM(SELECT Value AS      PU_Id,
                       Pu.Pu_Desc AS PU_Desc FROM Sheet_Display_Options AS a
                                                  JOIN @AllUnits AS Pu ON Pu.Pu_Id = a.value WHERE Display_Option_Id = 446
                UNION
                SELECT master_unit AS PU_Id,
                       pu.Pu_Desc AS  PU_Desc FROM Sheets AS s
                                                  JOIN @AllUnits AS Pu ON Pu.Pu_Id = s.master_unit WHERE s.Sheet_Type IN(1, 2, 23, 25)) AS PU
           ORDER BY PU_Desc
END
