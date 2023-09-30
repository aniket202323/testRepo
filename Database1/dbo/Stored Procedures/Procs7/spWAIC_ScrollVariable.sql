Create Procedure [dbo].[spWAIC_ScrollVariable]
@VariableId Int,
@ContextType int,
@Direction int,
@ContextData nvarchar(255) = Null --1=down 2=up
AS
Declare @NewVariable Int
-- See If There Is A Command To Process To Find The Next Variable
If @ContextType = 1
  Begin
 	  	 Declare @SheetId Int
 	  	 Declare @CurrentOrder Int
 	 
    -- 'Sheet' Context Type
    Select @SheetId = Sheet_id From Sheets where Sheet_Desc = @ContextData
    Select @CurrentOrder = var_order from Sheet_Variables where sheet_id = @SheetId and Var_id = @VariableId
    If @Direction = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select min(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7) 
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order > @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
    Else If @Direction = 2
      Begin
        -- Scroll Up
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select max(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7) 
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order < @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
  End
Else If @ContextType = 2
  Begin
 	  	 Declare @MasterUnit Int
    -- 'Unit' Context Type
    Select @MasterUnit = pu_id from Variables Where Var_Id = @VariableId
    Select @CurrentOrder = 1000 * g.pug_order + v.pug_order from variables v join pu_groups g on g.pug_id = v.pug_id where v.var_id = @VariableId
    If @Direction = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select min(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) > (@CurrentOrder)
                                 )
      End
    Else If @Direction = 2
      Begin
        -- Scroll Up
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select max(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) < (@CurrentOrder)
                                 )
      End
  End
--If we couldn't find a scroll candidate, just pass back
--the original.
If @NewVariable Is Null
 	 Set @NewVariable = @VariableId
Return @NewVariable
