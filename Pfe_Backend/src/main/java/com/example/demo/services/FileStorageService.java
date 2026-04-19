package com.example.demo.services;

import com.mongodb.client.gridfs.model.GridFSFile;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.gridfs.GridFsOperations;
import org.springframework.data.mongodb.gridfs.GridFsTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;

@Service
public class FileStorageService {

    @Autowired
    private GridFsTemplate gridFsTemplate;

    @Autowired
    private GridFsOperations gridFsOperations;

    // ── Store any file, return its GridFS ObjectId as String ──
    public String store(MultipartFile file) throws IOException {
        ObjectId fileId = gridFsTemplate.store(
            file.getInputStream(),
            file.getOriginalFilename(),
            file.getContentType()
        );
        return fileId.toString();
    }

    // ── Retrieve file metadata ──
    public GridFSFile findById(String id) {
        return gridFsTemplate.findOne(
            new Query(Criteria.where("_id").is(new ObjectId(id)))
        );
    }

    // ── Open the raw stream for a given GridFS file ──
    public InputStream getStream(GridFSFile file) throws IOException {
        return gridFsOperations.getResource(file).getInputStream();
    }

    // ── Get content type for a given GridFS file ──
    public String getContentType(GridFSFile file) throws IOException {
        return gridFsOperations.getResource(file).getContentType();
    }

    // ── Delete a file by ID ──
    public void delete(String id) {
        gridFsTemplate.delete(
            new Query(Criteria.where("_id").is(new ObjectId(id)))
        );
    }
}