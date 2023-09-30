


CREATE PROCEDURE [dbo].[spProdMetrics_GetUnitConfigurationDetails]

    @UnitList	nvarchar(max),
    @ConfigurationType nvarchar(100)



AS

    IF (@ConfigurationType <> 'OEE')
        Begin
            SELECT Code = 'InvalidData', ERROR = 'Fatal - InvalidConfigurationType', ErrorType = 'InvalidConfigurationType', PropertyName1 = 'ConfigurationType', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @ConfigurationType, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        End


    Create Table #Ids (Id Int)
INSERT INTO #Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@UnitList,',')

Select Pu.PU_Id as 'Pu_Id', CASE WHEN Production_Rate_Specification IS NOT NULL OR Table_Fields_Values.KeyId IS NOT NULL THEN 1 ELSE 0 END as 'IsConfigured', @ConfigurationType as 'ConfigurationType' from Prod_Units_Base Pu
                                                                                                                                                                                                                 LEFT JOIN Table_Fields_Values ON Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id
Where Pu.Pu_Id in (select * from #Ids);
