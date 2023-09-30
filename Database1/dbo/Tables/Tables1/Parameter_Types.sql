CREATE TABLE [dbo].[Parameter_Types] (
    [Parm_Type_Desc] VARCHAR (50) NOT NULL,
    [Parm_Type_Id]   TINYINT      NOT NULL,
    CONSTRAINT [PK_Parameter_Types] PRIMARY KEY NONCLUSTERED ([Parm_Type_Id] ASC),
    CONSTRAINT [Parameter_Types_UC_Desc] UNIQUE NONCLUSTERED ([Parm_Type_Desc] ASC)
);

