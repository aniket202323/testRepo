CREATE TABLE [dbo].[Dept_Parameters] (
    [Dept_Id]       INT           NOT NULL,
    [Parm_Id]       INT           NOT NULL,
    [Parm_Required] BIT           CONSTRAINT [DeptParameters_DF_Required] DEFAULT ((0)) NOT NULL,
    [Value]         VARCHAR (255) NOT NULL,
    CONSTRAINT [DeptParameters_PK_DeptIdParmId] PRIMARY KEY NONCLUSTERED ([Dept_Id] ASC, [Parm_Id] ASC),
    CONSTRAINT [DeptParams_FK_DeptId] FOREIGN KEY ([Dept_Id]) REFERENCES [dbo].[Departments_Base] ([Dept_Id]),
    CONSTRAINT [DeptParams_FK_ParamId] FOREIGN KEY ([Parm_Id]) REFERENCES [dbo].[Parameters] ([Parm_Id])
);

