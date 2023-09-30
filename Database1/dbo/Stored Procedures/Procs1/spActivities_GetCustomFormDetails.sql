
CREATE PROCEDURE dbo.spActivities_GetCustomFormDetails @SheetId INT

 AS
BEGIN
    DECLARE @Options TABLE(SheetId          INT,
                           Title            nVARCHAR(100),
                           ExternalURL      NVARCHAR(MAX),
                           URLConfiguration INT,
                           Username         nVARCHAR(MAX),
                           Password         nVARCHAR(MAX))


    DECLARE @UseTitles TINYINT;
    WITH CTE_SDO
         AS (
         SELECT DO.Display_Option_Id,
                SDO.Value
                FROM Display_Options AS DO
                     LEFT JOIN Sheet_Display_Options AS SDO ON SDO.Display_Option_Id = DO.Display_Option_Id
                WHERE DO.Display_Option_Id IN(462, 463, 464, 465)
                     AND SDO.Sheet_Id = @SheetId)
         INSERT INTO @Options( SheetId,
                               ExternalURL,
                               URLConfiguration,
                               Username,
                               Password )
         VALUES(@SheetId, (SELECT Value FROM CTE_SDO WHERE Display_Option_Id = 462), ISNULL((SELECT Value FROM CTE_SDO WHERE Display_Option_Id = 463), 0), (SELECT Value FROM CTE_SDO WHERE Display_Option_Id = 464), (SELECT Value FROM CTE_SDO WHERE Display_Option_Id = 465))

    INSERT INTO @Options( SheetId,
                          Title,
                          ExternalURL,
                          URLConfiguration,
                          Username,
                          Password )
    SELECT @SheetId,
           Title,
           External_URL_link,
           ISNULL(Open_URL_Configuration, 0),
           User_Login,
           Password FROM Sheet_Variables WHERE Sheet_Id = @SheetId
                                               AND Var_Id IS NULL;
    WITH CTE_FD
         AS (
         SELECT Field_Id,
                Field_Desc FROM ED_FieldType_ValidValues WHERE ED_Field_Type_Id = 82)
         SELECT SheetId,
                Title,
                ExternalURL,
                URLConfiguration AS URLConfigurationId,
                Field_Desc AS       URLConfiguration,
                Username,
                Password
                FROM @Options
                     JOIN CTE_FD ON Field_Id = URLConfiguration
END
