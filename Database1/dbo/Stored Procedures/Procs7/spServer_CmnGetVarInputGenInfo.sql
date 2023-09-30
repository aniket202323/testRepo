CREATE PROCEDURE dbo.spServer_CmnGetVarInputGenInfo
@VarId int
AS
select src.pu_id from PrdExec_inputs pei 
join PrdExec_Input_Sources src on src.pei_id = pei.pei_id
join variables_Base var on var.pei_id = pei.pei_id and var.pu_id = pei.pu_id
where var.var_id = @varid
