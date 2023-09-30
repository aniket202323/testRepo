CREATE PROCEDURE [dbo].[spMES_GetColorSchemeField]
					 @CategoryID int=NULL,
					 @ColorSchemeId int = 1

AS
BEGIN

    DECLARE @Sql nvarchar(max)= '';
    SET @Sql = 'SELECT CSC.Color_Scheme_Category_Id,
                    CSC.Color_Scheme_Category_Desc, CSF.Color_Scheme_Field_Id, CSF.Color_Scheme_Field_Desc,
                    COALESCE(CSD.Color_Scheme_Value, CSF.Default_Color_Scheme_Color) as Color, CS.CS_Id as Color_Scheme_Id, CS.CS_Desc as Color_Scheme_Desc
                    FROM Color_Scheme_Fields CSF
                    Join Color_Scheme_categories CSC On CSC.Color_Scheme_Category_Id = CSF.Color_Scheme_Category_Id'
                    if(@CategoryID is NOT NULL)
        BEGIN
            SET @Sql = @Sql+ ' and CSC.Color_Scheme_Category_Id = ' + cast(@CategoryID as nvarchar)
        END

        -- This is required in case the default color scheme is not changed then colors are not updated in Color_Scheme_Data, so it needs to be picked from Color_Scheme_Fields. But if it not default
        -- then we can do a Join instead of left Join(if cs_id is wrong empty resultset will be sent)
        if(@ColorSchemeId = 1)
            BEGIN
                SET @Sql = @Sql+     ' Left Join Color_Scheme CS On CS.CS_Id =  1'
            END
        ELSE
            BEGIN
                SET @Sql = @Sql+     ' Join Color_Scheme CS On CS.CS_Id =  '+ cast(@ColorSchemeId as nvarchar)
            END

        SET @Sql = @Sql + ' Left Join Color_Scheme_Data CSD On CSD.Color_Scheme_Field_Id = CSF.Color_Scheme_Field_Id AND CSD.CS_Id = CS.CS_Id'


    EXEC(@sql)


END


