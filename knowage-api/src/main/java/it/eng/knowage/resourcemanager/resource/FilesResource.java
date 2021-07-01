/*
 * Knowage, Open Source Business Intelligence suite
 * Copyright (C) 2021 Engineering Ingegneria Informatica S.p.A.
 *
 * Knowage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Knowage is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package it.eng.knowage.resourcemanager.resource;

import java.util.List;

import javax.validation.Valid;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;

import it.eng.knowage.resourcemanager.resource.utils.FileDTO;
import it.eng.knowage.resourcemanager.service.ResourceManagerAPI;
import it.eng.spagobi.services.security.SecurityServiceService;
import it.eng.spagobi.services.security.SpagoBIUserProfile;

@Path("/2.0/resources/files")
@Component
public class FilesResource {

	private static final Logger LOGGER = Logger.getLogger(FilesResource.class);

	@Autowired
	@Lazy
	SecurityServiceService securityServiceService;

	@Autowired
	ResourceManagerAPI resourceManagerAPIservice;

	// Files Management

	/**
	 * @param path
	 * @return list of files, one of them could be "metadata.json", it will be excluded
	 */
	@GET
	@Path("/{path}")
	@Produces(MediaType.APPLICATION_JSON)
	public List<FileDTO> files(@PathParam("path") String path) {
		List<FileDTO> files = null;
		return files;
	}

	@GET
	@Path("/download/file/{path}")
	@Produces(MediaType.APPLICATION_OCTET_STREAM)
	public Response downloadFiles(@QueryParam("path") String path) {
		return null;
	}

	@POST
	@Path("/uploadfile")
	@Consumes({ MediaType.MULTIPART_FORM_DATA, MediaType.APPLICATION_JSON })
	public Response uploadFile() {
		return null;

	}

	@GET
	@Path("/metadata/{path}")
	@Produces(MediaType.APPLICATION_JSON)
	public FileDTO metadata(@PathParam("path") String path) {
		FileDTO file = null;
		return file;
	}

	@PUT
	@Path("/metadata/{path}")
	@Produces(MediaType.APPLICATION_JSON)
	public FileDTO saveMetadata(@Valid FileDTO fileDTO, @PathParam("path") String path) {
		return null;
	}

	@POST
	@Path("/metadata/{path}")
	@Produces(MediaType.APPLICATION_JSON)
	public FileDTO addMetadata(@Valid FileDTO fileDTO, @PathParam("path") String path) {
		return null;
	}

	// Common methods

	@DELETE
	@Path("/{path}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response delete(@PathParam("path") String path) {
		Response response = null;

		return response;

	}

	private SpagoBIUserProfile getUserProfile() {
		SpagoBIUserProfile profile = (SpagoBIUserProfile) RequestContextHolder.currentRequestAttributes().getAttribute("userProfile",
				RequestAttributes.SCOPE_REQUEST);
		return profile;
	}

}
