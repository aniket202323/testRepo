Create Procedure dbo.spEM_GetVarLookup
  AS
  --
  -- Return variable lookup data.
  --
  SELECT VL_Id,
         Var_Id,
         Ext_Int_Key_1,
         Ext_Int_Key_2,
         Ext_Int_Key_3,
         Ext_Str_Key_1,
         Ext_Str_Key_2,
         Ext_Str_Key_3
    FROM Var_Lookup
