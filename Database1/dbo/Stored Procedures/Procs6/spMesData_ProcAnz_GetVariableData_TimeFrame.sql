
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetVariableData_TimeFrame]
    @varid INT = NULL,
    @starttime DATETIME = NULL,
    @endtime DATETIME = NULL,
    @result_on DATETIME = NULL,
    @plot_for NVARCHAR(50) = NULL

AS
DECLARE @ConvertedST 	 DateTime,
 	  	@ConvertedET 	 DateTime,
		@DbTZ			 nVarchar(200),
		@VarDesc		 nVARCHAR(100)

IF EXISTS (SELECT v.var_id
FROM Variables_Base v WITH(NOLOCK)
WHERE v.var_id = @varid)
BEGIN
    SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@starttime, 'UTC')
    SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endtime, 'UTC')
    SELECT @result_on = dbo.fnServer_CmnConvertToDbTime(@result_on, 'UTC')
    SELECT @DbTZ = VALUE
    FROM site_parameters
    WHERE parm_id = 192
    --converting output timestamp to UTC from DB timezone
    SELECT @VarDesc = Var_Desc FROM Variables_Base WHERE Var_Id = @varid
    IF(@plot_for = 'SPC')
    BEGIN
        SELECT
            T.var_id, @VarDesc AS varDesc, dbo.fnServer_CmnConvertTime(T.Entry_On, @DbTZ, 'UTC') AS startTime, T.Result
        FROM
            Tests T WITH(NOLOCK)
        WHERE
		t.var_id = @varid
            AND t.Entry_On BETWEEN @ConvertedST AND @ConvertedET
            AND T.Result_On <= CASE WHEN @result_on IS NULL THEN T.Result_On ELSE @result_on END
    END
    ELSE
        BEGIN
        SELECT
            T.var_id, @VarDesc AS varDesc, dbo.fnServer_CmnConvertTime(T.Result_On, @DbTZ, 'UTC') AS startTime, T.Result
        FROM
            Tests T WITH(NOLOCK)
        WHERE
            t.var_id = @varid
            AND t.Result_On BETWEEN @ConvertedST AND @ConvertedET
    END
END
ELSE
BEGIN
    -- Returning error when the entered Input ID is not present in DB
    SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
    RETURN
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetVariableData_TimeFrame] TO [ComXClient]