
CREATE PROCEDURE [dbo].[spRIS_GetVariables]
	@Pu_Id		INT,  
	@Prod_id		INT = NULL 
AS   

/*---------------------------------------------------------------------------------------------------------------------
    This procedure returns all quality variables if no product id is passed. If product id is passed, then it will return
	all quality variables that match the target specification for that product.
  
    Date         Ver/Build   Author              Story/Defect		Remarks
    31-Dec-2019  001         Bhavani			 US390388			Initial Development (Retrieve test results for a sample.)
	23-Jul-2020  002		 Evgeniy Kim		 DE139238			Only return active specs that have no expiration date
																	Added NOLOCK hints (but may need to remove them later)
																	Only return distinct variables	
	10-Sep-2020  003		 Evgeniy Kim		 US439593			Sampling engine does not allow Variable-wise sampling
	02-Nov-2020  004		 Evgeniy Kim		 Bug				Updated to handle multiple characteristics on product
---------------------------------------------------------------------------------------------------------------------
    NOTES: 
	1. During config, users may enter the same group name for different criterias, that's not a valid scenario, but 
	   if it does occur, that's why we are removing duplicate specification name below.
	2. If the expiration date in Active_Specs table is null, then it means there is a value in the specification.
	
	QUESTIONS:
	1. 


---------------------------------------------------------------------------------------------------------------------*/

IF(@Prod_id IS NULL)
BEGIN
	SELECT Var_Id, Var_Desc, Data_Type_Id, PU_Id, User_Defined1, Sampling_Interval FROM Variables WITH(NOLOCK) WHERE PU_Id = @Pu_Id;
END
ELSE 
BEGIN
	SELECT a.Var_Id, a.Var_Desc, a.Data_Type_Id, a.PU_Id, a.User_Defined1, a.Sampling_Interval FROM
		(SELECT	V.Var_Id, V.Var_Desc, V.Data_Type_Id, V.PU_Id, v.User_Defined1, v.Sampling_Interval,
				ROW_NUMBER() OVER (PARTITION BY V.Var_Desc ORDER BY V.Var_Id) AS RowNumber
		FROM	Product_Characteristic_Defaults Pcd WITH(NOLOCK)
		JOIN	Characteristics C WITH(NOLOCK)
		ON		C.Char_Id = Pcd.Char_Id
		JOIN	Products p WITH(NOLOCK)
		ON		P.Prod_Id = Pcd.Prod_Id
		JOIN	Product_Properties pp WITH(NOLOCK)
		ON		pp.Prop_Id = Pcd.Prop_Id
		AND		pp.Prop_Desc = N'Receiving and Inspection'
		JOIN	Specifications S  WITH(NOLOCK)
		ON		S.Prop_Id = C.Prop_Id
		JOIN	Active_Specs Specs  WITH(NOLOCK)
		ON		Specs.Spec_Id =S.Spec_Id 
		AND		Specs.Char_Id = C.Char_Id
		JOIN	PU_Groups pg WITH(NOLOCK)
		ON		pg.PUG_Desc = Specs.Target
		JOIN	Variables_Base v WITH(NOLOCK)
		ON		pg.PUG_Id = V.PUG_Id
		WHERE	Pg.Pu_Id =  @Pu_Id  
		AND		p.Prod_Id = @prod_id
		AND		Specs.Expiration_Date IS NULL) AS a
	WHERE RowNumber = 1;
 END