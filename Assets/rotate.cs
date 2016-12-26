using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class rotate : MonoBehaviour {

	public float speed = 1.0f;

	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		transform.RotateAround (transform.position, Vector3.up, Time.deltaTime * speed);	
	}
}
