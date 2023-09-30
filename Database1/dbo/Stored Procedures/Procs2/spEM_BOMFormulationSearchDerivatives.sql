--  spEM_BOMFormulationSearchDerivatives 12
CREATE PROCEDURE dbo.spEM_BOMFormulationSearchDerivatives
@key int,
@path int,
@order nvarchar(50),
@status int,
@stime datetime,
@etime datetime,
@desc nvarchar(50)
AS
select
 	 bomf.BOM_Formulation_Id,pep.Path_Code,pp.Process_Order,pps.PP_Status_Desc,bomf.Effective_Date,bomf.BOM_Formulation_Desc,c.Comment_Id
from
 	 Bill_Of_Material_Formulation bomf
 	 left join Production_Plan pp on bomf.BOM_Formulation_Id=pp.BOM_Formulation_Id
 	 left join Prdexec_Paths pep on pp.Path_Id=pep.Path_Id
 	 left join Production_Plan_Statuses pps on pp.PP_Status_Id=pps.PP_Status_Id
 	 left join Comments c on bomf.Comment_Id=c.Comment_Id
where
 	 bomf.Master_BOM_Formulation_Id=@key
 	 and (pp.Path_Id=@path or @path is null)
 	 and (pp.Process_Order like '%'+@order+'%' or @order is null)
 	 and (pp.PP_Status_Id=@status or @status is null)
 	 and (bomf.BOM_Formulation_Desc like '%'+@desc+'%' or @desc is null)
 	 and (bomf.Effective_Date>=@stime or @stime is null)
 	 and (bomf.Effective_Date<=@etime or @etime is null)
