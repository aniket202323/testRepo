CREATE TABLE [dbo].[Test_Sigma_Data] (
    [Entry_On] DATETIME   NOT NULL,
    [Mean]     FLOAT (53) NULL,
    [Sigma]    FLOAT (53) NULL,
    [Test_Id]  BIGINT     NOT NULL,
    CONSTRAINT [TestSigmaData_PK_TestId] PRIMARY KEY NONCLUSTERED ([Test_Id] ASC),
    CONSTRAINT [TestSigmaData_FK_Tests] FOREIGN KEY ([Test_Id]) REFERENCES [dbo].[Tests] ([Test_Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [TestSigmaData_IDX_EntryOn]
    ON [dbo].[Test_Sigma_Data]([Entry_On] ASC, [Test_Id] ASC);

