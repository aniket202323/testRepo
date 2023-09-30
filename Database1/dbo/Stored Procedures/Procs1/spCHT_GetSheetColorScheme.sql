/**********************************************/
/****** Called from ProfRVW also **************/
Create Procedure dbo.spCHT_GetSheetColorScheme 
@Sheet_Id int
AS
  -- Get color scheme information for a specific sheet
  Select cs.CS_Desc as Value from Color_Scheme cs
        join sheet_display_options sdo on sdo.Value = cs.CS_Id
 	 join display_options do on do.display_option_id = sdo.display_option_id
 	 where sdo.sheet_id = @Sheet_Id and do.display_option_desc = "Color Scheme"
