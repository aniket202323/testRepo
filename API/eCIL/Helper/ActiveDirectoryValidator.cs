using System;
using System.Collections.Generic;
using System.DirectoryServices;
using System.Linq;
using System.Web;

namespace eCIL.Helper
{
    public class ActiveDirectoryValidator
    {
        #region Variables
        private string _path;
        private string _filterAttribute;
        #endregion

        #region Properties
        public string Path { get => _path; set => _path = value; }
        public string FilterAttribute { get => _filterAttribute; set => _filterAttribute = value; }
        #endregion

        #region Methods
        public ActiveDirectoryValidator(string path)
        {
            _path = path;
        }

        public bool IsAuthenticated(string domainName, string userName, string password)
        {
            string domainAndUserName = string.Empty;
            DirectoryEntry entry;
            try
            {
                domainAndUserName = domainName + "\\" + userName;
                entry = new DirectoryEntry(_path, domainAndUserName, password);
                Object obj = entry.NativeObject;
                DirectorySearcher search = new DirectorySearcher(entry);
                search.Filter = "(SAMAccountName=" + userName + ")";
                search.PropertiesToLoad.Add("cn");
                SearchResult result = search.FindOne();
                if (result == null)
                    return false;

                //update the new path to the user in the directory
                _path = result.Path;
                _filterAttribute = result.Properties["cn"].ToString();
                return true;
            }
            catch
            {
                return false;
            }
        }
        #endregion
    }
}