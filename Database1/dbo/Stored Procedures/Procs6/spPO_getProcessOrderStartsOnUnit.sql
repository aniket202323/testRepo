
CREATE PROCEDURE dbo.spPO_getProcessOrderStartsOnUnit
@PP_Id	 			int,
@PP_Start_Id int





AS
    IF (@PP_Id is not null AND NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_Id = @PP_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    IF (@PP_Id is not null AND @PP_Start_Id is not null AND NOT EXISTS(SELECT 1 FROM Production_Plan_Starts WHERE PP_Id = @PP_Id AND PP_Start_Id = @PP_Start_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END


    IF (@PP_Start_Id is not null AND NOT EXISTS(SELECT 1 FROM Production_Plan_Starts WHERE PP_Start_Id = @PP_Start_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192

SELECT
    PP_Start_Id, PP_Id, Start_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Start_Time', End_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'End_Time', pub.PU_Id,pub.PU_Desc, Is_Production from Production_Plan_Starts pps
                LEFT JOIN Prod_Units_Base pub WITH (nolock) ON pps.PU_Id = pub.PU_Id
where (@PP_Id is null or pps.PP_Id = @PP_Id)
    AND (@PP_Start_Id IS NULL OR pps.PP_Start_Id = @PP_Start_Id)


    SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON
