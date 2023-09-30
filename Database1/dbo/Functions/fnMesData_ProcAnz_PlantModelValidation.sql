
CREATE FUNCTION [dbo].[fnMesData_ProcAnz_PlantModelValidation](
    @dept_id			int = NULL
    ,@line_id         int = NULL
    ,@pu_id           int = NULL
)
RETURNS  @ErrorInfo TABLE(
        Error                      nVARCHAR(255) NULL
        ,Code                      nVARCHAR(255) NULL
        ,ErrorType                 nVARCHAR(255) NULL
        ,PropertyName1             nVARCHAR(255) NULL
        ,PropertyName2             nVARCHAR(255) NULL
        ,PropertyName3             nVARCHAR(255) NULL
        ,PropertyName4             nVARCHAR(255) NULL
        ,PropertyValue1			 nVARCHAR(255) NULL
        ,PropertyValue2            nVARCHAR(255) NULL
        ,PropertyValue3			 nVARCHAR(255) NULL
        ,PropertyValue4			 nVARCHAR(255) NULL
    )
AS
BEGIN
    IF NOT EXISTS(Select 1 from dbo.Departments_Base WITH(NOLOCK) WHERE Dept_Id = @dept_id) AND @dept_id IS NOT NULL
    BEGIN
        INSERT INTO @ErrorInfo
        SELECT Error = 'ERROR: No Valid Department Found', Code = 'InvalidData', ErrorType = 'ValidDepartmentNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
    IF NOT EXISTS(Select 1 from dbo.Prod_Lines_Base WITH(NOLOCK) WHERE PL_Id = @line_id) AND @line_id IS NOT NULL
    BEGIN
        INSERT INTO @ErrorInfo
        SELECT Error = 'ERROR: No Valid Line Found', Code = 'InvalidData', ErrorType = 'ValidLineNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
    IF NOT EXISTS(Select 1 from dbo.Prod_Lines_Base WITH(NOLOCK) WHERE PL_Id = @line_id AND Dept_Id = @dept_id) AND @dept_id IS NOT NULL AND @line_id IS NOT NULL
    BEGIN
        INSERT INTO @ErrorInfo
        SELECT Error = 'ERROR: No Valid Line Found', Code = 'InvalidData', ErrorType = 'ValidLineNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
    IF NOT EXISTS(Select 1 from dbo.Prod_Units_Base WITH(NOLOCK) WHERE PU_Id = @pu_id AND PL_Id = @line_id) AND @line_id IS NOT NULL AND @pu_id IS NOT NULL
    BEGIN
        INSERT INTO @ErrorInfo
        SELECT Error = 'ERROR: No Valid Unit Found', Code = 'InvalidData', ErrorType = 'ValidUnitsNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
            IF NOT EXISTS(Select 1 from dbo.Prod_Units_Base WITH(NOLOCK) WHERE PU_Id = @pu_id) AND @pu_id IS NOT NULL 
    BEGIN
        INSERT INTO @ErrorInfo
        SELECT Error = 'ERROR: No Valid Unit Found', Code = 'InvalidData', ErrorType = 'ValidUnitsNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
RETURN
END