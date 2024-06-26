/*
 * Knowage, Open Source Business Intelligence suite
 * Copyright (C) 2016 Engineering Ingegneria Informatica S.p.A.

 * Knowage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Knowage is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package it.eng.spagobi.workspace.dao;

import java.util.List;

import it.eng.spagobi.commons.dao.ISpagoBIDao;
import it.eng.spagobi.workspace.bo.DocumentOrganizer;
import it.eng.spagobi.workspace.metadata.SbiObjFuncOrganizer;

/**
 * @deprecated Replaced by KNOWAGE_TM-513
 * TODO : Delete
 */
@Deprecated
public interface IObjFuncOrganizerDAO extends ISpagoBIDao {

	public List<DocumentOrganizer> loadDocumentsByFolder(Integer folderId);

	public SbiObjFuncOrganizer addDocumentToOrganizer(Integer documentId);

	public void removeDocumentFromOrganizer(Integer folderId, Integer docId);

	public void moveDocumentToDifferentFolder(Integer documentId, Integer sourceFolderId, Integer destinationFolderId);

	/**
	 * The method that collects all Organizer documents available for current user. It does not look for a particular folder, but rather for all documents that
	 * exist for the user.
	 *
	 * @return The list of all documents available in the user's Organizer.
	 * @author Danilo Ristovski (danristo, danilo.ristovski@mht.net)
	 */
	public List<DocumentOrganizer> loadAllOrganizerDocuments();

}