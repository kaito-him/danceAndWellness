package com.example.demo.entities;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "categories")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Category {
    @Id
    private String id;

    private String name;        // e.g. "Dance Fitness"
    private String icon;        // GridsFs
}

/*

package com.example.demo.entities;

	// 💃 Dance Styles
    BALLET,
    HIP_HOP,
    
    // 🧘 Mind & Body Wellness
    YOGA,
    MEDITATION,

    // 💪 Fitness & Movement
    DANCE_FITNESS,        
    STRETCHING_FLEXIBILITY,
    
    // 🌿 Holistic Health
    INJURY_PREVENTION,
    MENTAL_WELLNESS,
}
*/