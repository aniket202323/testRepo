Create Procedure dbo.spEMEPC_GetPreview
AS
SELECT PL_Id, PL_Desc
  FROM Prod_Lines
  where pl_id > 0
SELECT Distinct pu.PU_Id, PU_Desc, pu.PL_Id
  FROM Prod_Units pu
  Join prdexec_paths pe on pe.PL_Id = pu.PL_id
  WHERE pu.PU_Id > 0  
  ORDER BY pu.PL_Id
Select Distinct
pupi.pl_Id,
pupi.pu_desc,
Case When ppis.pepis_id is NOT NULL Then puppis.pu_desc Else pupis.pu_desc End as Source_PU_Desc, 
pi.PU_Id,
Case When ppis.pepis_id is NOT NULL Then ppis.pu_id Else pis.pu_id End as Source_PU_Id, 
Step = 1
From prdexec_Inputs pi
Join prdexec_input_sources pis on pis.PEI_Id = pi.PEI_Id
Join Prod_Units pupi on pupi.PU_Id = pi.PU_Id
Join prod_units pupis on pupis.pu_id = pis.pu_id
Join PrdExec_Paths pp on pp.pl_id = pupi.pl_id
Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pis.pei_id And ppis.path_id = pp.path_id and ppis.pu_id = pis.pu_id
Left Outer Join prod_units puppis on puppis.pu_id = ppis.pu_id
Where pupi.pl_id = pp.pl_id
order by pupi.pl_id
